import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/page/album/album_detail_page.dart';
import 'package:mix_music/page/album/album_page.dart';
import 'package:mix_music/page/app_music_history/app_history_music_list.dart';
import 'package:mix_music/page/app_playlist/app_playlist_page.dart';
import 'package:mix_music/page/artist/artist_page.dart';
import 'package:mix_music/page/download/download_page.dart';
import 'package:mix_music/page/home/home_page.dart';
import 'package:mix_music/page/mv/mv_detail_page.dart';
import 'package:mix_music/page/mv/mv_page.dart';
import 'package:mix_music/page/recommend/recommend_page.dart';
import 'package:mix_music/page/setting/download_setting_page.dart';
import 'package:mix_music/page/setting/extension_net_page.dart';
import 'package:mix_music/page/setting/extension_page.dart';
import 'package:mix_music/page/setting/login/login_by_cookie.dart';
import 'package:mix_music/page/setting/login/login_by_phone.dart';
import 'package:mix_music/page/setting/login/login_by_web.dart';
import 'package:mix_music/page/setting/play_setting_page.dart';
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
import '../page/setting/login_list_page.dart';
import '../page/setting/match_site_page.dart';
import '../page/welcome/welcome_page.dart';

class Routes {
  Routes._();

  // static const key = 1;
  static const String permission = "/permission";
  static const String extension = "/extension";
  static const String extensionNet = "/extensionNet";
  static const String welcome = "/welcome";

  static const String main = "/main";
  static const String appPlaying = "/appPlaying";
  static const String appPlayList = "/appPlayList";
  static const String appHistoryMusicList = "/appHistoryMusicList";
  static const String search = "/search";
  static const String download = "/download";
  static const String setting = "/setting";
  static const String downloadSetting = "/downloadSetting";
  static const String playSetting = "/playSetting";

  //每日推荐
  static const String recommend = "/recommend";

  static const String home = "/";
  static const String playList = "/playList";
  static const String playListDetail = "/playlistDetail";
  static const String matchSite = "/matchSite";
  static const String homeSite = "/homeSite";
  static const String loginListSetting = "/loginListSetting";
  static const String loginByCookie = "/loginByCookie";
  static const String loginByPhone = "/loginByPhone";
  static const String loginByWeb = "/loginByWeb";
  static const String album = "/album";
  static const String albumDetail = "/albumDetail";

  static const String mv = "/mv";
  static const String mvDetail = "/mvDetail";

  static const String rank = "/rank";
  static const String rankDetail = "/rankDetail";
  static const String artist = "/artist";
  static const String artistDetail = "/artistDetail";
  static const String parsePlayList = "/parsePlayList";

  static List<GetPage> routes = [
    GetPage(name: welcome, page: () => const WelcomePage(), customTransition: MyCustomTransition()),
    GetPage(name: permission, page: () => const PermissionPage(), customTransition: MyCustomTransition()),
    GetPage(name: extension, page: () => const ExtensionPage(), customTransition: MyCustomTransition()),
    GetPage(name: extensionNet, page: () => const ExtensionNetPage(), customTransition: MyCustomTransition()),
    GetPage(name: matchSite, page: () => const MatchSitePage(), customTransition: MyCustomTransition()),
    GetPage(name: homeSite, page: () => const HomeSitePage(), customTransition: MyCustomTransition()),
    GetPage(name: loginListSetting, page: () => const LoginListPage(), customTransition: MyCustomTransition()),
    GetPage(name: loginByCookie, page: () => const LoginByCookiePage(), customTransition: MyCustomTransition()),
    GetPage(name: loginByPhone, page: () => const LoginByPhonePage(), customTransition: MyCustomTransition()),
    GetPage(name: loginByWeb, page: () => const LoginByWebPage(), customTransition: MyCustomTransition()),
    GetPage(name: home, page: () => const HomePage(), customTransition: MyCustomTransition()),
    GetPage(name: setting, page: () => const SettingPage(), customTransition: MyCustomTransition()),
    GetPage(name: search, page: () => const SearchPage(), customTransition: MyCustomTransition()),
    GetPage(name: appPlayList, page: () => AppPlayListPage(), customTransition: MyCustomTransition()),
    GetPage(name: recommend, page: () => RecommendPage(), customTransition: MyCustomTransition()),
    GetPage(name: appHistoryMusicList, page: () => AppHistoryMusicList(), customTransition: MyCustomTransition()),
    GetPage(name: playList, page: () => const PlayListPage(), customTransition: MyCustomTransition()),
    GetPage(name: playListDetail, page: () => PlayListDetailPage(), customTransition: MyCustomTransition()),
    GetPage(name: album, page: () => const AlbumPage(), customTransition: MyCustomTransition()),
    GetPage(name: albumDetail, page: () => const AlbumDetailPage(), customTransition: MyCustomTransition()),
    GetPage(name: rank, page: () => const RankPage(), customTransition: MyCustomTransition()),
    GetPage(name: rankDetail, page: () => const RankDetailPage(), customTransition: MyCustomTransition()),
    GetPage(name: artist, page: () => const ArtistPage(), customTransition: MyCustomTransition()),
    GetPage(name: artistDetail, page: () => const ArtistDetailPage(), customTransition: MyCustomTransition()),
    GetPage(name: parsePlayList, page: () => const ParsePlayList(), customTransition: MyCustomTransition()),
    GetPage(name: download, page: () => const DownloadPage(), customTransition: MyCustomTransition()),
    GetPage(name: downloadSetting, page: () => const DownloadSettingPage(), customTransition: MyCustomTransition()),
    GetPage(name: playSetting, page: () => const PlaySettingPage(), customTransition: MyCustomTransition()),
    GetPage(name: mv, page: () => const MvPage(), customTransition: MyCustomTransition()),
    GetPage(name: mvDetail, page: () => const MvDetailPage(), customTransition: MyCustomTransition()),
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
  Widget buildTransition(BuildContext context, Curve? curve, Alignment? alignment, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return Opacity(opacity: animation.value, child: child);
  }
}
