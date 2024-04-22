import 'package:get/get.dart';
import 'package:mix_music/page/album/album_detail_page.dart';
import 'package:mix_music/page/album/album_page.dart';
import 'package:mix_music/page/app_playlist/app_playlist_page.dart';
import 'package:mix_music/page/artist/artist_page.dart';
import 'package:mix_music/page/home/home_page.dart';
import 'package:mix_music/page/mine/mine_page.dart';
import 'package:mix_music/page/parse/parse_play_list.dart';
import 'package:mix_music/page/permission/permission_page.dart';
import 'package:mix_music/page/playlist/play_list_detail_page.dart';
import 'package:mix_music/page/playlist/playlist_page.dart';
import 'package:mix_music/page/plugins/plugins_page.dart';
import 'package:mix_music/page/rank/rank_detail_page.dart';
import 'package:mix_music/page/rank/rank_page.dart';
import 'package:mix_music/page/search/search_page.dart';
import 'package:mix_music/page/setting/home_site_page.dart';

import '../page/artist/artist_detail_page.dart';
import '../page/setting/match_site_page.dart';
import '../page/welcome/welcome_page.dart';

class Routes {
  Routes._();

  // static const key = 1;
  static const String permission = "/permission";
  static const String plugins = "/plugins";
  static const String welcome = "/welcome";

  static const String main = "/main";
  static const String appPlaying = "/appPlaying";
  static const String appPlayList = "/appPlayList";
  static const String search = "/search";
  static const String mine = "/mine";
  static const String home = "/";
  static const String playList = "/playList";
  static const String playListDetail = "/playlistDetail";
  static const String matchSite = "/matchSite";
  static const String homeSite = "/homeSite";
  static const String album = "/album";
  static const String albumDetail = "/albumDetail";

  static const String rank = "/rank";
  static const String rankDetail = "/rankDetail";
  static const String artist = "/artist";
  static const String artistDetail = "/artistDetail";
  static const String parsePlayList = "/parsePlayList";

  static List<GetPage> routes = [
    GetPage(name: welcome, page: () => const WelcomePage()),
    GetPage(name: permission, page: () => const PermissionPage()),
    GetPage(name: plugins, page: () => const PluginsPage()),
    GetPage(name: matchSite, page: () => const MatchSitePage()),
    GetPage(name: homeSite, page: () => const HomeSitePage()),
    GetPage(name: home, page: () => const HomePage()),
    GetPage(name: mine, page: () => const MinePage()),
    GetPage(name: search, page: () => const SearchPage()),
    GetPage(name: appPlayList, page: () => AppPlayListPage()),
    GetPage(name: playList, page: () => const PlayListPage()),
    GetPage(name: playListDetail, page: () => const PlayListDetailPage()),
    GetPage(name: album, page: () => const AlbumPage()),
    GetPage(name: albumDetail, page: () => const AlbumDetailPage()),
    GetPage(name: rank, page: () => const RankPage()),
    GetPage(name: rankDetail, page: () => const RankDetailPage()),
    GetPage(name: artist, page: () => const ArtistPage()),
    GetPage(name: artistDetail, page: () => const ArtistDetailPage()),
    GetPage(name: parsePlayList, page: () => const ParsePlayList()),
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
