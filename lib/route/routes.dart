import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/entity/mix_album.dart';
import 'package:mix_music/entity/mix_rank.dart';
import 'package:mix_music/page/album/album_detail_page.dart';
import 'package:mix_music/page/album/album_page.dart';
import 'package:mix_music/page/app_main/app_main_page.dart';
import 'package:mix_music/page/app_playing/app_playing_page.dart';
import 'package:mix_music/page/app_playlist/app_playlist_page.dart';
import 'package:mix_music/page/home/home_page.dart';
import 'package:mix_music/page/permission/permission_page.dart';
import 'package:mix_music/page/playlist/play_list_detail_page.dart';
import 'package:mix_music/page/playlist/playlist_page.dart';
import 'package:mix_music/page/plugins/plugins_page.dart';
import 'package:mix_music/page/rank/rank_detail_page.dart';
import 'package:mix_music/page/rank/rank_page.dart';
import 'package:mix_music/page/search/search_page.dart';

import '../entity/mix_play_list.dart';
import '../page/setting/match_site_page.dart';

class Routes {
  Routes._();

  static const key = 1;
  static const String permission = "/permission";
  static const String plugins = "/plugins";

  static const String main = "/main";
  static const String appPlaying = "/appPlaying";
  static const String appPlayList = "/appPlayList";
  static const String search = "/search";
  static const String home = "/";
  static const String playList = "/playList";
  static const String playListDetail = "/playlistDetail";
  static const String matchSite = "/matchSite";
  static const String album = "/album";
  static const String albumDetail = "/albumDetail";

  static const String rank = "/rank";
  static const String rankDetail = "/rankDetail";

  static List<GetPage> routes = [
    GetPage(name: main, page: () => AppMainPage()),
    GetPage(name: permission, page: () => const PermissionPage()),
    GetPage(name: plugins, page: () => const PluginsPage()),
    GetPage(name: matchSite, page: () => const MatchSitePage()),
  ];

  static Route<dynamic> getRoute(RouteSettings settings) {
    var route = settings.name;
    var arguments = settings.arguments;
    switch (route) {
      case home:
        return GetPageRoute(settings: settings, page: () => const HomePage());
      case search:
        return GetPageRoute(settings: settings, page: () => const SearchPage());
      case appPlaying:
        return GetPageRoute(settings: settings, page: () => AppPlayingPage());
      case appPlayList:
        return GetPageRoute(settings: settings, page: () => AppPlayListPage(inPanel: false));
      case playList:
        return GetPageRoute(settings: settings, page: () => const PlayListPage());
      case playListDetail:
        return GetPageRoute(settings: settings, page: () => PlayListDetailPage(playlist: arguments as MixPlaylist?));
      case album:
        return GetPageRoute(settings: settings, page: () => const AlbumPage());
      case albumDetail:
        return GetPageRoute(settings: settings, page: () => AlbumDetailPage(album: arguments as MixAlbum?));
      case rank:
        return GetPageRoute(settings: settings, page: () => const RankPage());
      case rankDetail:
        return GetPageRoute(settings: settings, page: () => RankDetailPage(rank: arguments as MixRank?));

      default:
        return GetPageRoute(settings: settings, page: () => Center(child: Text("404", style: Theme.of(Get.context!).textTheme.displayLarge)));
    }
  }
}
