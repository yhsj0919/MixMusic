import 'dart:io';

import 'package:flutter_js/quickjs/ffi.dart';
import 'package:mix_music/api/mix_api.dart';
import 'package:mix_music/utils/plugins_ext.dart';
import 'package:path_provider/path_provider.dart';

import '../entity/mix_song.dart';
import '../entity/plugins_info.dart';
import 'music_api.dart';

class ApiFactory {
  static final List<PluginsInfo> _plugins = [];
  static final _apis = <String, MusicApi>{};
  static final _matchSite = <String>{};
  static bool _matchVip = false;
  static var _pluginRoot = "";

  static matchVip(bool match) {
    _matchVip = match;
  }

  static bool getMatchVip() {
    return _matchVip;
  }

  static setMatchSite(Set<String> sites) {
    _matchSite.clear();
    _matchSite.addAll(sites);
  }

  static Set<String> getMatchSite() {
    return _matchSite;
  }

  static PluginsInfo getPlugin(int index) {
    return _plugins[index];
  }

  static List<PluginsInfo> getPlugins() {
    return _plugins;
  }

  static init({required String pluginRoot}) async {
    _pluginRoot = pluginRoot;

    await getSystemPlugins(rootDir: pluginRoot).then((value) {
      _plugins.clear();
      _apis.clear();
      _plugins.addAll(value);
      _plugins.forEach((element) async {
        var api = await MixApi.api(plugins: element);
        _apis[element.site!] = api;
      });
    });
  }

  static reFreshPlugins() async {
    await getSystemPlugins(rootDir: _pluginRoot).then((value) {
      _plugins.clear();
      _plugins.addAll(value);
      _plugins.forEach((element) async {
        var api = await MixApi.api(plugins: element);
        _apis[element.site!] = api;
      });
    });
  }

  /// 工厂方法
  static MusicApi? api({required String site}) {
    if (_apis.containsKey(site)) {
      return _apis[site];
    }
    return null;
  }

  ///获取播放地址
  static Future<MixSong> playUrl({required String site, required MixSong song}) {
    if (song.vip == 1 && _matchVip && !_matchSite.contains(site) && _matchSite.isNotEmpty) {
      return matchMusic(sites: _matchSite.toList(), name: song.title, artist: song.artist?.first.name).then((value) {
        return value.firstOrNull ?? song;
      });
    } else {
      return api(site: site)!.playUrl(song);
    }
  }

  static Future<List<MixSong>> _searchMusic({required String site, required String? name, required String? artist}) async {
    var keyWord = "$name $artist";
    try {
      var value = await ApiFactory.api(site: site)?.searchSong(keyword: keyWord, page: 0, size: 20);
      return value?.data ?? [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<MixSong>> matchMusic({required List<String> sites, required String? name, required String? artist}) async {
    var value = await Future.wait(sites.map((e) => _searchMusic(site: e, name: name, artist: artist)));

    var datas = value
        .map((e) {
          e.forEach((element) {
            print('${element.site}  ${element.title}>>${name}  ${element.subTitle}>>${artist}');
          });
          var data = e.firstWhereOrNull((element) =>
              (element.title.toString().replaceAll(" ", "").toLowerCase().startsWith(name.toString().replaceAll(" ", "").toLowerCase()) ||
                  name.toString().replaceAll(" ", "").toLowerCase().startsWith(element.title.toString().replaceAll(" ", "").toLowerCase())) &&
              ((element.subTitle.toString().replaceAll(" ", "").toLowerCase().contains(artist?.replaceAll(" ", "").toLowerCase() ?? "")) ||
                  (artist ?? "").toString().replaceAll(" ", "").toLowerCase().contains(element.subTitle.replaceAll(" ", "").toLowerCase() ?? "")));
          return data;
        })
        .where((element) => element != null)
        .toList();
    // datas.forEach((element) {
    //   print("${element?.site} ==> ${element?.title} ${element?.subTitle}");
    // });

    try {
      var urls = (await Future.wait(datas.map((e) {
        return ApiFactory.api(site: e!.site)!.playUrl(e);
      })))
          .where((element) => element.url?.isNotEmpty == true)
          .toList();

      return urls;
    } catch (e) {
      return [];
    }
  }
}
