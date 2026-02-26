import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:mix_music/common/entity/mix_album.dart';
import 'package:mix_music/common/entity/mix_artist.dart';
import 'package:mix_music/common/entity/mix_mv.dart';
import 'package:mix_music/common/entity/mix_play_list.dart';
import 'package:mix_music/common/entity/mix_rank.dart';
import 'package:mix_music/common/entity/plugins_info.dart';
import 'package:mix_music/desktop/desktop_main_page.dart';
import 'package:mix_music/page/album/album_detail_page.dart';
import 'package:mix_music/page/album/album_page.dart';
import 'package:mix_music/page/album/desktop/desktop_album_detail_page.dart';
import 'package:mix_music/page/album/desktop/desktop_album_page.dart';
import 'package:mix_music/page/app_music_history/app_history_music_list.dart';
import 'package:mix_music/page/app_playing/phone_playing.dart';
import 'package:mix_music/page/app_playlist/app_playlist_page.dart';
import 'package:mix_music/page/artist/artist_page.dart';
import 'package:mix_music/page/artist/desktop/desktop_artist_detail_page.dart';
import 'package:mix_music/page/artist/desktop/desktop_artist_page.dart';
import 'package:mix_music/page/download/desktop_download_page.dart';
import 'package:mix_music/page/download/download_page.dart';
import 'package:mix_music/page/home/desktop_home_page.dart';
import 'package:mix_music/page/home/mobile_home_main.dart';
import 'package:mix_music/page/home/mobile_home_page.dart';
import 'package:mix_music/page/mv/desktop/desktop_mv_page.dart';
import 'package:mix_music/page/mv/mv_detail_page.dart';
import 'package:mix_music/page/mv/mv_page.dart';
import 'package:mix_music/page/parse/parse_play_list.dart';
import 'package:mix_music/page/permission/permission_page.dart';
import 'package:mix_music/page/playlist/desktop/desktop_play_list_detail_page.dart';
import 'package:mix_music/page/playlist/desktop/desktop_playlist_page.dart';
import 'package:mix_music/page/playlist/play_list_detail_page.dart';
import 'package:mix_music/page/playlist/playlist_page.dart';
import 'package:mix_music/page/rank/desktop/desktop_rank_detail_page.dart';
import 'package:mix_music/page/rank/desktop/desktop_rank_page.dart';
import 'package:mix_music/page/rank/rank_detail_page.dart';
import 'package:mix_music/page/rank/rank_page.dart';
import 'package:mix_music/page/recommend/desktop_recommend_page.dart';
import 'package:mix_music/page/recommend/recommend_page.dart';
import 'package:mix_music/page/search/desktop/desktop_search_page.dart';
import 'package:mix_music/page/search/mobile/search_page.dart';
import 'package:mix_music/page/setting/about/about_page.dart';
import 'package:mix_music/page/setting/about/desktop_about_page.dart';
import 'package:mix_music/page/setting/desktop_setting_page.dart';
import 'package:mix_music/page/setting/download/desktop_download_setting_page.dart';
import 'package:mix_music/page/setting/download/download_setting_page.dart';
import 'package:mix_music/page/setting/extension/desktop_extension_detail_page.dart';
import 'package:mix_music/page/setting/extension/desktop_extension_net_page.dart';
import 'package:mix_music/page/setting/extension/desktop_extension_page.dart';
import 'package:mix_music/page/setting/extension/extension_net_page.dart';
import 'package:mix_music/page/setting/extension/extension_page.dart';
import 'package:mix_music/page/setting/home/desktop_home_site_page.dart';
import 'package:mix_music/page/setting/home/home_site_page.dart';
import 'package:mix_music/page/setting/login/desktop_login_by_cookie.dart';
import 'package:mix_music/page/setting/login/desktop_login_by_phone.dart';
import 'package:mix_music/page/setting/login/desktop_login_by_web.dart';
import 'package:mix_music/page/setting/login/desktop_login_list_page.dart';
import 'package:mix_music/page/setting/login/login_by_cookie.dart';
import 'package:mix_music/page/setting/login/login_by_phone.dart';
import 'package:mix_music/page/setting/login/login_by_web.dart';
import 'package:mix_music/page/setting/match/desktop_match_site_page.dart';
import 'package:mix_music/page/setting/play/desktop_play_setting_page.dart';
import 'package:mix_music/page/setting/play/play_setting_page.dart';
import 'package:mix_music/page/setting/setting_page.dart';

import '../page/app_music_history/desktop_app_history_music_list.dart';
import '../page/artist/artist_detail_page.dart';
import '../page/parse/desktop_parse_play_list.dart';
import '../page/setting/login/login_list_page.dart';
import '../page/setting/match/match_site_page.dart';
import '../page/welcome/welcome_page.dart';

class Routes {
  Routes._();

  static const key = 1;
  static const String permission = "/permission";
  static const String extension = "/extension";
  static const String extensionDetail = "/extensionDetail";
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
  static const String about = "/about";
  static const String playing = "/playing";

  static List<GetPage> mobileRoutes = [
    GetPage(name: welcome, page: () => const WelcomePage(), customTransition: MyCustomTransition()),
    GetPage(name: home, page: () => const MobileHomeMain(), customTransition: MyCustomTransition()),
    GetPage(name: playing, page: () => PhonePlaying(), customTransition: MyCustomTransition()),
    // GetPage(name: permission, page: () => const PermissionPage(), customTransition: MyCustomTransition()),
    // GetPage(name: extension, page: () => const ExtensionPage(), customTransition: MyCustomTransition()),
    // GetPage(name: extensionNet, page: () => const ExtensionNetPage(), customTransition: MyCustomTransition()),
    // GetPage(name: matchSite, page: () => const MatchSitePage(), customTransition: MyCustomTransition()),
    // GetPage(name: homeSite, page: () => const HomeSitePage(), customTransition: MyCustomTransition()),
    // GetPage(name: loginListSetting, page: () => const LoginListPage(), customTransition: MyCustomTransition()),
    // GetPage(name: loginByCookie, page: () => const LoginByCookiePage(), customTransition: MyCustomTransition()),
    // GetPage(name: loginByPhone, page: () => const LoginByPhonePage(), customTransition: MyCustomTransition()),
    // GetPage(name: loginByWeb, page: () => const LoginByWebPage(), customTransition: MyCustomTransition()),
    // GetPage(name: home, page: () => const MobileHomePage(), customTransition: MyCustomTransition()),
    // GetPage(name: setting, page: () => const SettingPage(), customTransition: MyCustomTransition()),
    // GetPage(name: about, page: () => const AboutPage(), customTransition: MyCustomTransition()),
    // GetPage(name: search, page: () => const SearchPage(), customTransition: MyCustomTransition()),
    // GetPage(name: appPlayList, page: () => AppPlayListPage(), customTransition: MyCustomTransition()),
    // GetPage(name: recommend, page: () => RecommendPage(), customTransition: MyCustomTransition()),
    // GetPage(name: appHistoryMusicList, page: () => AppHistoryMusicList(), customTransition: MyCustomTransition()),
    // GetPage(name: playList, page: () => const PlayListPage(), customTransition: MyCustomTransition()),
    // GetPage(name: playListDetail, page: () => PlayListDetailPage(), customTransition: MyCustomTransition()),
    // GetPage(name: album, page: () => const AlbumPage(), customTransition: MyCustomTransition()),
    // GetPage(name: albumDetail, page: () => const AlbumDetailPage(), customTransition: MyCustomTransition()),
    // GetPage(name: rank, page: () => const RankPage(), customTransition: MyCustomTransition()),
    // GetPage(name: rankDetail, page: () => const RankDetailPage(), customTransition: MyCustomTransition()),
    // GetPage(name: artist, page: () => const ArtistPage(), customTransition: MyCustomTransition()),
    // GetPage(name: artistDetail, page: () => const ArtistDetailPage(), customTransition: MyCustomTransition()),
    // GetPage(name: parsePlayList, page: () => const ParsePlayList(), customTransition: MyCustomTransition()),
    // GetPage(name: download, page: () => const DownloadPage(), customTransition: MyCustomTransition()),
    // GetPage(name: downloadSetting, page: () => const DownloadSettingPage(), customTransition: MyCustomTransition()),
    // GetPage(name: playSetting, page: () => const PlaySettingPage(), customTransition: MyCustomTransition()),
    // GetPage(name: mv, page: () => const MvPage(), customTransition: MyCustomTransition()),
    GetPage(
      name: mvDetail,
      page: () => MvDetailPage(mv: Get.arguments),
      customTransition: MyCustomTransition(),
    ),
  ];

  static Route<dynamic> getMobileRoute(RouteSettings settings) {
    var route = settings.name;
    // var arguments = settings.arguments as Map<String, String>?;
    switch (route) {
      case permission:
        return GetPageRoute(page: () => const PermissionPage(), customTransition: MyCustomTransition());
      case extension:
        return GetPageRoute(page: () => const ExtensionPage(), customTransition: MyCustomTransition());
      case extensionNet:
        return GetPageRoute(page: () => const ExtensionNetPage(), customTransition: MyCustomTransition());
      case matchSite:
        return GetPageRoute(page: () => const MatchSitePage(), customTransition: MyCustomTransition());
      case homeSite:
        return GetPageRoute(page: () => const HomeSitePage(), customTransition: MyCustomTransition());
      case loginListSetting:
        return GetPageRoute(page: () => const LoginListPage(), customTransition: MyCustomTransition());
      case loginByCookie:
        return GetPageRoute(
          page: () => LoginByCookiePage(plugins: settings.arguments as PluginsInfo),
          customTransition: MyCustomTransition(),
        );
      case loginByPhone:
        return GetPageRoute(
          page: () => LoginByPhonePage(plugins: settings.arguments as PluginsInfo),
          customTransition: MyCustomTransition(),
        );
      case loginByWeb:
        return GetPageRoute(
          page: () => LoginByWebPage(plugins: settings.arguments as PluginsInfo),
          customTransition: MyCustomTransition(),
        );
      case main:
        return GetPageRoute(page: () => const MobileHomePage(), customTransition: MyCustomTransition());
      case setting:
        return GetPageRoute(page: () => const SettingPage(), customTransition: MyCustomTransition());
      case about:
        return GetPageRoute(page: () => const AboutPage(), customTransition: MyCustomTransition());
      case search:
        return GetPageRoute(page: () => const SearchPage(), customTransition: MyCustomTransition());
      case appPlayList:
        return GetPageRoute(page: () => AppPlayListPage(), customTransition: MyCustomTransition());
      case recommend:
        return GetPageRoute(page: () => RecommendPage(), customTransition: MyCustomTransition());
      case appHistoryMusicList:
        return GetPageRoute(page: () => AppHistoryMusicList(), customTransition: MyCustomTransition());
      case playList:
        return GetPageRoute(page: () => const PlayListPage(), customTransition: MyCustomTransition());
      case playListDetail:
        return GetPageRoute(
          page: () => PlayListDetailPage(playlist: settings.arguments as MixPlaylist),
          customTransition: MyCustomTransition(),
        );
      case album:
        return GetPageRoute(page: () => const AlbumPage(), customTransition: MyCustomTransition());
      case albumDetail:
        return GetPageRoute(
          page: () => AlbumDetailPage(album: settings.arguments as MixAlbum),
          customTransition: MyCustomTransition(),
        );
      case rank:
        return GetPageRoute(page: () => const RankPage(), customTransition: MyCustomTransition());
      case rankDetail:
        return GetPageRoute(
          page: () => RankDetailPage(rank: settings.arguments as MixRank),
          customTransition: MyCustomTransition(),
        );
      case artist:
        return GetPageRoute(page: () => const ArtistPage(), customTransition: MyCustomTransition());
      case artistDetail:
        return GetPageRoute(
          page: () => ArtistDetailPage(artist: settings.arguments as MixArtist),
          customTransition: MyCustomTransition(),
        );
      case parsePlayList:
        return GetPageRoute(page: () => const ParsePlayList(), customTransition: MyCustomTransition());
      case download:
        return GetPageRoute(page: () => const DownloadPage(), customTransition: MyCustomTransition());
      case downloadSetting:
        return GetPageRoute(page: () => const DownloadSettingPage(), customTransition: MyCustomTransition());
      case playSetting:
        return GetPageRoute(page: () => const PlaySettingPage(), customTransition: MyCustomTransition());
      case mv:
        return GetPageRoute(page: () => const MvPage(), customTransition: MyCustomTransition());
      // case mvDetail:
      //   return GetPageRoute(
      //     page: () => MvDetailPage(mv: settings.arguments as MixMv),
      //     customTransition: MyCustomTransition(),
      //   );

      default:
        if (route == "/") {
          return GetPageRoute(page: () => MobileHomePage());
        } else {
          return GetPageRoute(
            page: () => Scaffold(
              appBar: AppBar(),
              body: Center(child: Text("页面丢失", style: Theme.of(Get.context!).textTheme.headlineLarge)),
            ),
          );
        }
    }
  }

  static final rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  // BuildContext get currentContext {
  //   if (Platform.isAndroid) {
  //     return Get.context!;
  //   }
  //   return _shellNavigatorKey.currentContext!;
  // }

  static final desktopRouter = GoRouter(
    navigatorKey: rootNavigatorKey,
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return DesktopMainPage(shellContext: _shellNavigatorKey.currentContext, state: state, child: child);
        },

        routes: [
          GoRoute(path: home, builder: (context, state) => DesktopHomePage()),
          GoRoute(path: download, builder: (context, state) => DesktopDownloadPage()),
          GoRoute(path: appHistoryMusicList, builder: (context, state) => DesktopAppHistoryMusicList()),
          GoRoute(path: search, builder: (context, state) => DesktopSearchPage()),
          GoRoute(path: recommend, builder: (context, state) => DesktopRecommendPage()),
          GoRoute(path: artist, builder: (context, state) => DesktopArtistPage()),
          GoRoute(
            path: artistDetail,
            pageBuilder: (context, state) => FluentTransitionPage(
              key: state.pageKey,
              child: DesktopArtistDetailPage(item: state.extra as MixArtist),
            ),
          ),
          GoRoute(path: rank, builder: (context, state) => DesktopRankPage()),
          GoRoute(
            path: rankDetail,
            pageBuilder: (context, state) => FluentTransitionPage(
              key: state.pageKey,
              child: DesktopRankDetailPage(item: state.extra as MixRank),
            ),
          ),
          GoRoute(path: playList, builder: (context, state) => DesktopPlayListPage()),
          GoRoute(
            path: playListDetail,
            pageBuilder: (context, state) => FluentTransitionPage(
              key: state.pageKey,
              child: DesktopPlayListDetailPage(item: state.extra as MixPlaylist),
            ),
          ),
          GoRoute(path: album, builder: (context, state) => DesktopAlbumPage()),
          GoRoute(
            path: albumDetail,
            pageBuilder: (context, state) => FluentTransitionPage(
              key: state.pageKey,
              child: DesktopAlbumDetailPage(item: state.extra as MixAlbum),
            ),
          ),
          GoRoute(path: mv, builder: (context, state) => DesktopMvPage()),
          GoRoute(path: setting, builder: (context, state) => DesktopSettingPage()),
          GoRoute(
            path: about,
            pageBuilder: (context, state) => FluentTransitionPage(key: state.pageKey, child: DesktopAboutPage()),
          ),
          GoRoute(
            path: extension,
            pageBuilder: (context, state) => FluentTransitionPage(key: state.pageKey, child: DesktopExtensionPage()),
          ),
          GoRoute(
            path: extensionDetail,
            pageBuilder: (context, state) => FluentTransitionPage(
              key: state.pageKey,
              child: DesktopExtensionDetailPage(pluginInfo: state.extra as PluginsInfo),
            ),
          ),

          GoRoute(
            path: extensionNet,
            pageBuilder: (context, state) => FluentTransitionPage(key: state.pageKey, child: DesktopExtensionNetPage()),
          ),
          GoRoute(
            path: matchSite,
            pageBuilder: (context, state) => FluentTransitionPage(key: state.pageKey, child: DesktopMatchSitePage()),
          ),

          GoRoute(
            path: homeSite,
            pageBuilder: (context, state) => FluentTransitionPage(key: state.pageKey, child: DesktopHomeSitePage()),
          ),
          GoRoute(
            path: loginListSetting,
            pageBuilder: (context, state) => FluentTransitionPage(key: state.pageKey, child: DesktopLoginListPage()),
          ),
          GoRoute(
            path: loginByCookie,
            pageBuilder: (context, state) => FluentTransitionPage(
              key: state.pageKey,
              child: DesktopLoginByCookiePage(plugin: state.extra as PluginsInfo),
            ),
          ),
          GoRoute(
            path: loginByPhone,
            pageBuilder: (context, state) => FluentTransitionPage(
              key: state.pageKey,
              child: DesktopLoginByPhonePage(plugin: state.extra as PluginsInfo),
            ),
          ),
          GoRoute(
            path: loginByWeb,
            pageBuilder: (context, state) => FluentTransitionPage(
              key: state.pageKey,
              child: DesktopLoginByWebPage(plugin: state.extra as PluginsInfo),
            ),
          ),

          GoRoute(
            path: downloadSetting,
            pageBuilder: (context, state) => FluentTransitionPage(key: state.pageKey, child: DesktopDownloadSettingPage()),
          ),
          GoRoute(
            path: playSetting,
            pageBuilder: (context, state) => FluentTransitionPage(key: state.pageKey, child: DesktopPlaySettingPage()),
          ),
          GoRoute(
            path: parsePlayList,
            pageBuilder: (context, state) => FluentTransitionPage(key: state.pageKey, child: DesktopParsePlayList()),
          ),
        ],
      ),
    ],
  );
}

// _animation(Widget child) {
//   return Animate(child: child).moveY(begin: 20, end: 0, curve: Curves.easeOutCubic);
// }

class FluentTransitionPage<T> extends CustomTransitionPage<T> {
  FluentTransitionPage({
    required super.child,
    super.key,
    Duration duration = const Duration(milliseconds: 200),
    Duration reverseDuration = const Duration(milliseconds: 200),
    Curve curve = Curves.easeOutCubic,
    Offset beginOffset = const Offset(0, 0.1), // 默认从下往上
  }) : super(
         transitionDuration: duration,
         reverseTransitionDuration: reverseDuration,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           final curved = CurvedAnimation(parent: animation, curve: curve);

           final slideAnimation = Tween<Offset>(begin: beginOffset, end: Offset.zero).animate(curved);

           return SlideTransition(
             position: slideAnimation,
             child: FadeTransition(opacity: curved, child: child),
           );
         },
       );
}

class MyCustomTransition extends CustomTransition {
  @override
  Widget buildTransition(BuildContext context, Curve? curve, Alignment? alignment, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return Opacity(opacity: animation.value, child: child);
  }
}
