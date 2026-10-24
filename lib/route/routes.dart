import 'package:go_router/go_router.dart';
import 'package:lemon_x/lemon_x.dart';

import '../common/player/player_controller.dart';
import '../common/download/download_controller.dart';
import '../page/download/download_page.dart';
import '../common/entity/music_collection.dart';
import '../common/entity/artist.dart';
import '../common/entity/mv.dart';
import '../page/music_list/music_list_page.dart';
import '../page/music_list/music_list_controller.dart';
import '../page/app_playing/playing_page.dart';
import '../page/equalizer/equalizer_page.dart';
import '../page/setting/cache/cache_setting_page.dart';
import '../page/artist/artist_detail_album.dart';
import '../page/rank/rank_page.dart';
import '../page/recommend/recommend_page.dart';
import '../page/library/library_page.dart';
import '../page/parse/parse_play_list.dart';
import '../page/comment/comment_page.dart';
import '../common/entity/song.dart';
import '../common/history/playback_history_store.dart';
import '../page/app_music_history/app_history_music_list.dart';

import '../common/plugin/plugin_controller.dart';
import '../common/plugin/collection_controller.dart';
import '../page/playlist/play_list_detail_page.dart';
import '../page/mv/mv_detail_page.dart';
import '../common/local/local_music_controller.dart';
import '../page/local/local_music_page.dart';
import '../page/setting/local/music_directories_page.dart';

import '../page/home/home_page.dart';
import '../page/home/home_layout.dart';
import '../page/search/search_page.dart';
import '../page/setting/setting_controller.dart';
import '../page/setting/setting_page.dart';
import '../page/setting/update/update_page.dart';
import '../page/setting/match_setting_page.dart';
import '../page/setting/lyric_match_setting_page.dart';
import '../page/setting/extension/extension_page.dart';
import '../page/setting/extension/extension_ui_page.dart';

GoRouter createRouter(SettingController settings) => GoRouter(
  routes: [
    ShellRoute(
      builder: (context, state, child) =>
          HomeLayout(path: state.uri.path, child: child),
      routes: [
        GoRoute(
          path: '/history',
          builder: (context, state) => AppHistoryMusicList(
            store: context.lx.find<PlaybackHistoryStore>(),
          ),
        ),
        GoRoute(
          path: '/comments',
          builder: (context, state) => CommentPage(
            plugins: context.lx.find<PluginController>(),
            song: state.extra! as Song,
          ),
        ),
        GoRoute(
          path: '/parse',
          builder: (context, state) =>
              ParsePlayList(plugins: context.lx.find<PluginController>()),
        ),
        GoRoute(
          path: '/library',
          builder: (context, state) =>
              LibraryPage(plugins: context.lx.find<PluginController>()),
        ),
        for (final (path, kind) in [
          ('/playlists', MusicListKind.playlist),
          ('/albums', MusicListKind.album),
          ('/artists', MusicListKind.artist),
          ('/mvs', MusicListKind.mv),
        ])
          GoRoute(
            path: path,
            builder: (context, state) => MusicListPage(
              plugins: context.lx.find<PluginController>(),
              kind: kind,
            ),
          ),
        GoRoute(
          path: '/settings/downloads',
          builder: (context, state) =>
              DownloadPage(controller: context.lx.find<DownloadController>()),
        ),
        GoRoute(
          path: '/settings/cache',
          builder: (context, state) => CacheSettingPage(
            cache: context.lx.find<PlayerController>().cache,
          ),
        ),
        GoRoute(
          path: '/equalizer',
          builder: (context, state) => EqualizerPage(
            controller: context.lx.find<PlayerController>().equalizer,
          ),
        ),
        GoRoute(
          path: '/ranks',
          builder: (context, state) =>
              RankPage(plugins: context.lx.find<PluginController>()),
        ),
        GoRoute(
          path: '/artist/albums',
          builder: (context, state) => ArtistDetailAlbum(
            collection: context.lx.find<PluginController>().collection(
              CollectionKind.artist,
              state.extra! as Artist,
            ),
          ),
        ),
        GoRoute(
          path: '/playing',
          builder: (context, state) =>
              PlayingPage(player: context.lx.find<PlayerController>()),
        ),
        GoRoute(
          path: '/local',
          builder: (context, state) => LocalMusicPage(
            controller: context.lx.find<LocalMusicController>(),
          ),
        ),
        GoRoute(
          path: '/settings/local',
          builder: (context, state) => MusicDirectoriesPage(
            controller: context.lx.find<LocalMusicController>(),
          ),
        ),
        GoRoute(
          path: '/mv',
          builder: (context, state) => MvDetailPage(
            plugins: context.lx.find<PluginController>(),
            resource: state.extra! as Mv,
          ),
        ),
        GoRoute(
          path: '/recommend',
          builder: (context, state) =>
              RecommendPage(plugins: context.lx.find<PluginController>()),
        ),
        for (final kind in CollectionKind.values.where(
          (kind) => kind != CollectionKind.recommend,
        ))
          GoRoute(
            path: '/${kind.name}',
            builder: (context, state) => PlayListDetailPage(
              collection: context.lx.find<PluginController>().collection(
                kind,
                state.extra! as MusicCollection,
              ),
            ),
          ),
        GoRoute(
          path: '/settings/extensions/ui',
          builder: (context, state) => ExtensionUiPage(
            pluginId: state.uri.queryParameters['plugin']!,
            route: state.uri.queryParameters['route']!,
          ),
        ),
        GoRoute(
          path: '/settings/extensions',
          builder: (context, state) => const ExtensionPage(),
        ),
        GoRoute(path: '/', builder: (context, state) => const HomePage()),
        GoRoute(
          path: '/search',
          builder: (context, state) => const SearchPage(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => SettingPage(controller: settings),
        ),
        GoRoute(
          path: '/settings/update',
          builder: (context, state) => const UpdatePage(),
        ),
        GoRoute(
          path: '/settings/lyric-matching',
          builder: (context, state) => LyricMatchSettingPage(
            plugins: context.lx.find<PluginController>(),
          ),
        ),
        GoRoute(
          path: '/settings/matching',
          builder: (context, state) =>
              MatchSettingPage(plugins: context.lx.find<PluginController>()),
        ),
      ],
    ),
  ],
);
