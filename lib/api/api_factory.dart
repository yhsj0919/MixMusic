import 'package:flutter/foundation.dart';
import 'package:flutter_js/quickjs/ffi.dart';
import 'package:mix_music/constant.dart';
import 'package:mix_music/entity/mix_play_list.dart';
import 'package:mix_music/api/mix_api.dart';
import 'package:mix_music/utils/sp.dart';

import '../entity/mix_song.dart';
import '../entity/plugins_info.dart';
import 'music_api.dart';

class ApiFactory {
  ApiFactory._();

  static final List<PluginsInfo> _plugins = [];
  static final _apis = <String, MusicApi>{};

  static final _matchSite = <String>{};
  static bool _matchVip = false;

  static PluginsInfo? getPlugin(String? package) {
    return _plugins.firstWhereOrNull((e) => e.package == package);
  }

  static init() async {
    //初始化音源匹配
    initMatch();

    List<PluginsInfo> plugins = Sp.getList(Constant.KEY_EXTENSION) ?? [];
    _plugins.clear();
    _apis.clear();
    _plugins.addAll(plugins);

    for (var element in _plugins) {
      var api = MixApi.api(plugins: element);
      _apis[element.package!] = await api;
    }
  }

  static initMatch() async {
    _matchSite.clear();
    //初始化音源匹配
    _matchVip = Sp.getBool(Constant.KEY_MATCH_VIP) ?? false;
    _matchSite.addAll(Sp.getStringList(Constant.KEY_MATCH_SITE) ?? []);
  }

  /// 获取搜索api
  static List<PluginsInfo> getSearchPlugins({String type = "music"}) {
    return getPlugins(key: type, obj: "music.search");
  }

  static List<String> getSearchKey() {
    return _getKey();
  }

  /// 获取歌单api
  static List<PluginsInfo> getPlayListPlugins() {
    return getPlugins(key: "playList");
  }

  static List<PluginsInfo> getUrlPlugins() {
    return getPlugins(key: "url");
  }

  static List<PluginsInfo> getAlbumPlugins() {
    return getPlugins(key: "album");
  }

  static List<PluginsInfo> getRecPlugins() {
    return getPlugins(key: "rec");
  }

  static List<PluginsInfo> getRankPlugins() {
    return getPlugins(key: "rank");
  }

  static List<PluginsInfo> getArtistPlugins() {
    return getPlugins(key: "artist");
  }

  static List<PluginsInfo> getParsePlugins() {
    return getPlugins(key: "parse");
  }

  static List<String> getSearchMethod(String? package) {
    return api(package: package ?? "")?.keys(obj: "music.search") ?? [];
  }

  static List<String> getArtistMethod(String? package) {
    return api(package: package ?? "")?.keys(obj: "music.artist.detail") ?? [];
  }

  static List<PluginsInfo> getPlugins({String? key, String obj = "music"}) {
    if (key == null) return _plugins;

    var list = <PluginsInfo>[];
    _apis.forEach((mapKey, value) {
      if (value.contains(key: key, obj: obj)) {
        list.add(_plugins.firstWhere((v) => v.package == mapKey));
      }
    });
    return list;
  }

  static List<String> _getKey() {
    var list = <String>{};
    _apis.forEach((mapKey, value) {
      var ss = value.keys(obj: "music.search");
      list.addAll(ss);
    });
    return list.toList();
  }

  /// 工厂方法
  static MusicApi? api({required String package}) {
    if (_apis.containsKey(package)) {
      return _apis[package];
    }
    return null;
  }

  ///获取播放地址
  static Future<MixSong> playUrl({required String package, required MixSong song}) {
    if (song.vip == 1 && _matchVip && !_matchSite.contains(package) && _matchSite.isNotEmpty) {
      return matchMusic(packages: _matchSite.toList(), name: song.title, artist: song.artist?.first.title).then((value) {
        var matchSong = value.firstOrNull;

        song.match = matchSong != null;
        song.matchSong = matchSong;

        return song;
      });
    } else {
      return api(package: package)!.playUrl(song);
    }
  }

  static Future<List<MixSong>> _searchMusic({required String package, required String? name, required String? artist}) async {
    var keyWord = "$name $artist";
    try {
      var value = await ApiFactory.api(package: package)?.searchMusic(keyword: keyWord, page: 0, size: 20);
      return value?.data ?? [];
    } catch (e) {
      return [];
    }
  }

  static Future<MixPlaylist?> _parsePlayList({required String package, required String? url}) async {
    try {
      var value = await ApiFactory.api(package: package)?.parsePlayList(url: url);
      return value?.data;
    } catch (e) {
      return null;
    }
  }

  static Future<List<MixSong>> matchMusic({required List<String> packages, required String? name, required String? artist}) async {
    var value = await Future.wait(packages.map((e) => _searchMusic(package: e, name: name, artist: artist)));

    var datas = value
        .map((e) {
          for (var element in e) {
            if (kDebugMode) {
              print('${element.package}  ${element.title}>>$name  ${element.subTitle}>>$artist');
            }
          }
          var data = e.firstWhereOrNull((element) =>
              (element.title.toString().replaceAll(" ", "").toLowerCase().startsWith(name.toString().replaceAll(" ", "").toLowerCase()) ||
                  name.toString().replaceAll(" ", "").toLowerCase().startsWith(element.title.toString().replaceAll(" ", "").toLowerCase())) &&
              ((element.subTitle.toString().replaceAll(" ", "").toLowerCase().contains(artist?.replaceAll(" ", "").toLowerCase() ?? "")) ||
                  (artist ?? "").toString().replaceAll(" ", "").toLowerCase().contains(element.subTitle.replaceAll(" ", "").toLowerCase() ?? "")));
          return data;
        })
        .where((element) => element != null)
        .toList();

    try {
      var urls = (await Future.wait(datas.map((e) {
        return ApiFactory.api(package: e!.package)!.playUrl(e);
      })))
          .where((element) => element.url?.isNotEmpty == true)
          .toList();

      return urls;
    } catch (e) {
      return [];
    }
  }

  static Future<List<MixPlaylist?>> parsePlayList({required List<String> packages, required String? url}) async {
    var value = await Future.wait(packages.map((e) => _parsePlayList(package: e, url: url)));
    var datas = value.where((element) => element != null).toList();
    try {
      return datas;
    } catch (e) {
      return [];
    }
  }
}
