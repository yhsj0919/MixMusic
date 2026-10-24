import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lemon_net/lemon_net.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mix_music/page/setting/update/update_controller.dart';

Map<String, dynamic> release(
  String version, {
  String branch = 'v2',
  bool preview = false,
  bool draft = false,
}) => {
  'tag_name': version,
  'name': 'MixMusic $version',
  'body': '修复播放恢复',
  'target_commitish': branch,
  'draft': draft,
  'prerelease': preview,
  'html_url': 'https://github.com/yhsj0919/MixMusic/releases/tag/$version',
  'assets': [
    {
      'name': 'MixMusic-arm64.apk',
      'size': 1024,
      'state': 'uploaded',
      'browser_download_url':
          'https://github.com/yhsj0919/MixMusic/releases/download/$version/MixMusic-arm64.apk',
    },
    {
      'name': 'unfinished.zip',
      'size': 0,
      'state': 'new',
      'browser_download_url':
          'https://github.com/yhsj0919/MixMusic/releases/download/$version/unfinished.zip',
    },
  ],
};

void main() {
  late HttpServer server;
  late UpdateController controller;
  Object? body = {};
  var status = 200;
  var requests = 0;
  var plainText = false;
  Completer<void>? gate;
  Completer<void>? arrived;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'MixMusic',
      packageName: 'com.example.mix_music.v2',
      version: '0.1.0',
      buildNumber: '1',
      buildSignature: '',
    );
    body = release('v0.2.0');
    status = 200;
    requests = 0;
    plainText = false;
    gate = null;
    arrived = null;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      requests++;
      expect(
        request.uri.path,
        '/yhsj0919/MixMusic/updates/${controller.channel.value == UpdateChannel.stable ? 'stable' : 'preview'}.json',
      );
      expect(request.uri.queryParameters, isEmpty);
      arrived?.complete();
      await gate?.future;
      request.response.statusCode = status;
      request.response.headers.contentType = plainText
          ? ContentType.text
          : ContentType.json;
      request.response.write(jsonEncode(body));
      await request.response.close();
    });
    controller = UpdateController(
      net: LemonNet('http://${server.address.address}:${server.port}'),
    );
  });

  tearDown(() async {
    if (!controller.isDisposed) await controller.disposeController();
    await server.close(force: true);
  });

  test(
    'manual check reads stable manifest regardless of release target branch',
    () async {
      expect(requests, 0);
      expect(controller.result.isLoading, isFalse);
      expect(controller.channel.value, UpdateChannel.stable);
      body = release('v0.10.0', branch: 'master');
      await controller.check();
      final result = controller.result.value!;
      expect(result.available, isTrue);
      expect(result.release!.version.toString(), '0.10.0');
      expect(result.release!.notes, '修复播放恢复');
      expect(result.release!.assets.single.name, 'MixMusic-arm64.apk');
      expect(
        result.release!.assets.single.url.toString(),
        contains('/download/v0.10.0/'),
      );
    },
  );

  test(
    'preview channel includes prereleases, skips drafts and persists',
    () async {
      await controller.setChannel(UpdateChannel.preview);
      body = [
        release('v0.9.0'),
        release('v0.10.0-beta.2', preview: true),
        release('v0.10.0-beta.10', preview: true),
        release('v99.0.0', draft: true),
        release('nightly'),
      ];
      await controller.check();
      expect(
        controller.result.value!.release!.version.toString(),
        '0.10.0-beta.10',
      );
      expect(controller.result.value!.available, isTrue);
      final restored = UpdateController();
      addTearDown(restored.disposeController);
      await restored.restored;
      expect(restored.channel.value, UpdateChannel.preview);
      await controller.setChannel(UpdateChannel.stable);
      expect(controller.result.value, isNull);
      body = release('v0.2.0', branch: 'master');
      await controller.check();
      expect(controller.result.value!.release!.version.toString(), '0.2.0');
    },
  );

  test(
    'empty preview channel does not claim current version is latest',
    () async {
      await controller.setChannel(UpdateChannel.preview);
      body = [];
      await controller.check();
      expect(controller.result.value!.release, isNull);
      expect(controller.result.value!.available, isFalse);
    },
  );

  test('same or older release never offers downgrade', () async {
    for (final tag in ['v0.1.0', 'v0.1.0+1', 'v0.0.9']) {
      body = release(tag);
      await controller.check();
      expect(controller.result.value!.available, isFalse, reason: tag);
    }
    body = release('v0.1.0+2');
    await controller.check();
    expect(controller.result.value!.available, isTrue);
  });

  test('raw GitHub text content is decoded as JSON', () async {
    plainText = true;
    await controller.check();
    expect(controller.result.value!.release!.version.toString(), '0.2.0');
    await controller.setChannel(UpdateChannel.preview);
    body = [release('v0.3.0-beta.1', preview: true)];
    await controller.check();
    expect(
      controller.result.value!.release!.version.toString(),
      '0.3.0-beta.1',
    );
    await controller.setChannel(UpdateChannel.stable);
    body = null;
    await controller.check();
    expect(controller.result.value!.release, isNull);
  });

  test('missing Latest is distinct from network failure', () async {
    status = 404;
    body = {'message': 'Not Found'};
    await controller.check();
    expect(controller.result.value!.release, isNull);
    status = 429;
    body = {'message': 'API rate limit exceeded'};
    await controller.check();
    expect(controller.result.hasError, isTrue);
    expect(controller.result.errorValue, contains('GitHub 暂时限制'));
    expect(controller.result.value, isNull);
    status = 200;
    body = release('v0.2.0');
    await controller.check();
    expect(controller.result.value!.available, isTrue);
  });

  test(
    'malformed response and HTTP failure do not report up to date',
    () async {
      body = {'invalid': true};
      await controller.check();
      expect(controller.result.hasError, isTrue);
      status = 500;
      await controller.check();
      expect(controller.result.errorValue, contains('HTTP 500'));
    },
  );

  test(
    'nonstable or invalid Latest is not offered as a formal update',
    () async {
      for (final data in [
        release('v1.0.0', preview: true),
        release('v1.0.0', draft: true),
        release('v1.0.0-beta.1'),
        release('nightly'),
      ]) {
        body = data;
        await controller.check();
        expect(controller.result.hasError, isTrue);
        expect(controller.result.value, isNull);
      }
    },
  );

  test('concurrent checks issue one request', () async {
    gate = Completer<void>();
    arrived = Completer<void>();
    final first = controller.check();
    await arrived!.future.timeout(const Duration(seconds: 5));
    await controller.check();
    expect(requests, 1);
    gate!.complete();
    await first;
    expect(controller.result.hasData, isTrue);
  });

  test('disposal while checking does not update disposed state', () async {
    gate = Completer<void>();
    arrived = Completer<void>();
    final pending = controller.check();
    await arrived!.future.timeout(const Duration(seconds: 5));
    await controller.disposeController();
    gate!.complete();
    await pending;
    expect(controller.isDisposed, isTrue);
  });

  test('closed connection gives Chinese network failure', () async {
    await server.close(force: true);
    await controller.check();
    expect(controller.result.errorValue, '网络连接失败，请检查网络后重试');
  });

  test('invalid download links do not launch external apps', () async {
    await expectLater(
      controller.open(Uri.parse('file:///unsafe')),
      throwsStateError,
    );
    await expectLater(
      controller.open(Uri.parse('https:invalid')),
      throwsStateError,
    );
  });
}
