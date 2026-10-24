import 'package:flutter/foundation.dart';
import 'package:lemon_net/lemon_net.dart';
import 'package:lemon_x/lemon_x.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

enum UpdateChannel {
  stable('正式版'),
  preview('测试版（含正式版）');

  const UpdateChannel(this.title);
  final String title;
}

class UpdateAsset {
  UpdateAsset(this.name, this.url, this.size);
  final String name;
  final Uri url;
  final int size;
}

class UpdateRelease {
  UpdateRelease(this.version, this.title, this.notes, this.url, this.assets);
  final Version version;
  final String title, notes;
  final Uri url;
  final List<UpdateAsset> assets;

  factory UpdateRelease.fromJson(Map data) => UpdateRelease(
    Version.parse(
      (data['tag_name'] as String).replaceFirst(RegExp(r'^[vV]'), ''),
    ),
    data['name'] as String? ?? data['tag_name'] as String,
    data['body'] as String? ?? '',
    Uri.parse(data['html_url'] as String),
    [
      for (final item in data['assets'] as List)
        if (item['state'] == 'uploaded')
          UpdateAsset(
            item['name'] as String,
            Uri.parse(item['browser_download_url'] as String),
            item['size'] as int,
          ),
    ],
  );
}

class UpdateCheck {
  UpdateCheck(this.current, this.release);
  final Version current;
  final UpdateRelease? release;
  bool get available => release != null && release!.version > current;
}

class UpdateController extends LxController {
  UpdateController({LemonNet? net})
    : net =
          net ??
          LemonNet(
            'https://api.github.com',
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 20),
            headers: {
              'Accept': 'application/vnd.github+json',
              'User-Agent': 'MixMusic',
            },
          ) {
    result.data(null);
    restored = _restore();
  }

  static const repository = 'yhsj0919/MixMusic';
  static final releasesUrl = Uri.https('github.com', '/$repository/releases');
  final LemonNet net;
  late final Future<void> restored;
  late SharedPreferences _preferences;
  late final channel = own(UpdateChannel.stable.obs);
  late final package = PackageInfo.fromPlatform();
  late final result = own(RxAsync<UpdateCheck?>());

  Future<void> _restore() async {
    _preferences = await SharedPreferences.getInstance();
    if (isDisposed) return;
    channel.value = UpdateChannel.values.firstWhere(
      (value) => value.name == _preferences.getString('updateChannel'),
      orElse: () => UpdateChannel.stable,
    );
  }

  Future<void> setChannel(UpdateChannel value) async {
    try {
      await restored;
      if (isDisposed || result.isLoading || channel.value == value) return;
      channel.value = value;
      result.data(null);
      await _preferences.setString('updateChannel', value.name);
    } catch (error, stack) {
      debugPrint('[Update] 保存渠道失败：$error\n$stack');
      if (!isDisposed) result.error('更新渠道保存失败，请重试');
    }
  }

  Future<void> check() async {
    if (isDisposed || result.isLoading) return;
    result.loading();
    try {
      await restored;
      final info = await package;
      if (isDisposed) return;
      final current = Version.parse(
        '${info.version}${info.buildNumber.isEmpty ? '' : '+${info.buildNumber}'}',
      );
      final stable = channel.value == UpdateChannel.stable;
      final response = await net.get<dynamic>(
        '/repos/$repository/releases${stable ? '/latest' : ''}',
        queryParameters: stable ? null : {'per_page': 100},
      );
      if (isDisposed) return;
      if (response.statusCode == 403 || response.statusCode == 429) {
        throw StateError('GitHub 暂时限制了访问，请稍后重试');
      }
      if (response.statusCode == 404) {
        result.data(UpdateCheck(current, null));
        return;
      }
      if (response.statusCode != 200) {
        throw StateError('更新服务请求失败（HTTP ${response.statusCode}）');
      }
      UpdateRelease? latest;
      for (final data in stable ? [response.data] : response.data as List) {
        if (data['draft'] == true || (stable && data['prerelease'] == true)) {
          if (stable) throw StateError('GitHub Latest 未提供正式版本');
          continue;
        }
        UpdateRelease release;
        try {
          release = UpdateRelease.fromJson(data as Map);
        } on FormatException {
          if (stable) rethrow;
          continue;
        }
        if (stable && release.version.isPreRelease) {
          throw StateError('GitHub Latest 未提供正式版本');
        }
        if (latest == null || release.version > latest.version) {
          latest = release;
        }
      }
      result.data(UpdateCheck(current, latest));
    } catch (error, stack) {
      debugPrint('[Update] $error\n$stack');
      if (isDisposed) return;
      final message = switch (error) {
        StateError() => error.message,
        DioException() => '网络连接失败，请检查网络后重试',
        _ => '无法读取版本信息，请稍后重试',
      };
      result.error(message, stack);
    }
  }

  Future<void> open(Uri url) async {
    if (url.scheme != 'https' || !url.hasAuthority) throw StateError('更新链接无效');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw StateError('无法打开浏览器，请稍后重试');
    }
  }

  @override
  void onDispose() => net.close(force: true);
}
