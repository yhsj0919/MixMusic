import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/page/album/album_detail_page.dart';
import 'package:mix_music/page/album/album_page.dart';
import 'package:mix_music/page/app_playlist/app_playlist_page.dart';
import 'package:mix_music/page/artist/artist_page.dart';
import 'package:mix_music/page/home/home_page.dart';
import 'package:mix_music/page/setting/extension_page.dart';
import 'package:mix_music/page/setting/setting_page.dart';
import 'package:mix_music/page/parse/parse_play_list.dart';
import 'package:mix_music/page/permission/permission_page.dart';
import 'package:mix_music/page/playlist/play_list_detail_page.dart';
import 'package:mix_music/page/playlist/playlist_page.dart';
import 'package:mix_music/page/rank/rank_detail_page.dart';
import 'package:mix_music/page/rank/rank_page.dart';
import 'package:mix_music/page/search/search_page.dart';
import 'package:mix_music/page/setting/home_site_page.dart';
import 'package:mix_music/widgets/OpacityRoute.dart';

import '../page/artist/artist_detail_page.dart';
import '../page/setting/cookie_page.dart';
import '../page/setting/match_site_page.dart';
import '../page/welcome/welcome_page.dart';

class Routes {
  Routes._();

  // static const key = 1;
  static const String permission = "/permission";
  static const String extension = "/extension";
  static const String welcome = "/welcome";

  static const String main = "/main";
  static const String appPlaying = "/appPlaying";
  static const String appPlayList = "/appPlayList";
  static const String search = "/search";
  static const String download = "/download";
  static const String setting = "/setting";
  static const String home = "/";
  static const String playList = "/playList";
  static const String playListDetail = "/playlistDetail";
  static const String matchSite = "/matchSite";
  static const String homeSite = "/homeSite";
  static const String cookieSetting = "/cookieSetting";
  static const String album = "/album";
  static const String albumDetail = "/albumDetail";

  static const String rank = "/rank";
  static const String rankDetail = "/rankDetail";
  static const String artist = "/artist";
  static const String artistDetail = "/artistDetail";
  static const String parsePlayList = "/parsePlayList";

  static List<GetPage> routes = [
    GetPage(name: welcome, page: () => const WelcomePage(), customTransition: MyCustomTransition()),
    GetPage(name: permission, page: () => const PermissionPage(), customTransition: MyCustomTransition()),
    GetPage(name: extension, page: () => const ExtensionPage(), customTransition: MyCustomTransition()),
    GetPage(name: matchSite, page: () => const MatchSitePage(), customTransition: MyCustomTransition()),
    GetPage(name: homeSite, page: () => const HomeSitePage(), customTransition: MyCustomTransition()),
    GetPage(name: cookieSetting, page: () => const CookiePage(), customTransition: MyCustomTransition()),
    GetPage(name: home, page: () => const HomePage(), customTransition: MyCustomTransition()),
    GetPage(name: setting, page: () => const SettingPage(), customTransition: MyCustomTransition()),
    GetPage(name: search, page: () => const SearchPage(), customTransition: MyCustomTransition()),
    GetPage(name: appPlayList, page: () => AppPlayListPage(), customTransition: MyCustomTransition()),
    GetPage(name: playList, page: () => const PlayListPage(), customTransition: MyCustomTransition()),
    GetPage(name: playListDetail, page: () => PlayListDetailPage(), customTransition: MyCustomTransition()),
    GetPage(name: album, page: () => const AlbumPage(), customTransition: MyCustomTransition()),
    GetPage(name: albumDetail, page: () => const AlbumDetailPage(), customTransition: MyCustomTransition()),
    GetPage(name: rank, page: () => const RankPage(), customTransition: MyCustomTransition()),
    GetPage(name: rankDetail, page: () => const RankDetailPage(), customTransition: MyCustomTransition()),
    GetPage(name: artist, page: () => const ArtistPage(), customTransition: MyCustomTransition()),
    GetPage(name: artistDetail, page: () => const ArtistDetailPage(), customTransition: MyCustomTransition()),
    GetPage(name: parsePlayList, page: () => const ParsePlayList(), customTransition: MyCustomTransition()),
  ];

// static Route<dynamic> getRoute(RouteSettings settings) {
//   var route = settings.name;
//   var arguments = settings.arguments;
//   switch (route) {
//
//
//     default:
//       return GetPageRoute(settings: settings, page: () => Center(child: Text("404", style: Theme.of(Get.context!).textTheme.displayLarge)));
//   }
// }
}

class MyCustomTransition extends CustomTransition {
  @override
  Widget buildTransition(BuildContext context, Curve? curve, Alignment? alignment, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return Opacity(opacity: animation.value, child: child);
  }
}
