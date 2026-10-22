import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lemon_ui/lemon_ui.dart';

import '../app_playing/player_page.dart';

class HomeLayout extends StatelessWidget {
  const HomeLayout({super.key, required this.path, required this.child});

  final String path;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final device = HyperDeviceDetector.of(context);
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final desktop = device == HyperDeviceType.desktop;
    final tabletPlayer = device == HyperDeviceType.tablet && landscape;
    final page = path.startsWith('/settings')
        ? Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 840),
              child: child,
            ),
          )
        : child;

    if (tabletPlayer && path != '/playing') {
      return HyperScaffold(
        body: SafeArea(
          top: false,
          child: Row(
            children: [
              const Expanded(
                child: SafeArea(
                  bottom: false,
                  child: PlayerPage(expanded: true),
                ),
              ),
              Expanded(child: page),
            ],
          ),
        ),
      );
    }

    return HyperScaffold(
      appBar: desktop
          ? HyperAppBar(
              title: const SizedBox.shrink(),
              automaticallyImplyLeading: false,
              leading: HyperIconButton.ghost(
                key: const ValueKey('desktop-back'),
                tooltip: '返回',
                icon: const HyperIcon(Icons.arrow_back_rounded),
                onPressed: path == '/'
                    ? null
                    : () => context.canPop()
                          ? context.pop()
                          : context.go(switch (path) {
                              '/settings/extensions/ui' =>
                                '/settings/extensions',
                              '/settings/extensions' => '/settings',
                              '/settings/local' => '/settings',
                              '/settings/cache' => '/settings',
                              '/settings/downloads' => '/settings',
                              _ => '/',
                            }),
              ),
            )
          : null,
      body: SafeArea(
        top: false,
        child: desktop
            ? Row(
                children: [
                  HyperSidebar(
                    selectedId: path,
                    onSelected: (id) => context.go(id),
                    header: const Padding(
                      padding: EdgeInsets.all(16),
                      child: HyperText(
                        'MixMusic',
                        variant: HyperTextVariant.bodyLarge,
                      ),
                    ),
                    items: const [
                      HyperSidebarItem(
                        id: '/',
                        label: '推荐',
                        icon: HyperIcon(Icons.home_outlined),
                      ),
                      HyperSidebarItem(
                        id: '/search',
                        label: '搜索',
                        icon: HyperIcon(Icons.search),
                      ),
                      HyperSidebarItem(
                        id: '/local',
                        label: '本地音乐',
                        icon: HyperIcon(Icons.folder_outlined),
                      ),
                      HyperSidebarItem(
                        id: '/library',
                        label: '我的',
                        icon: HyperIcon(Icons.library_music_outlined),
                      ),
                      HyperSidebarItem(
                        id: '/ranks',
                        label: '排行榜',
                        icon: HyperIcon(Icons.leaderboard_outlined),
                      ),
                      HyperSidebarItem(
                        id: '/recommend',
                        label: '每日推荐',
                        icon: HyperIcon(Icons.today_outlined),
                      ),
                      HyperSidebarItem(
                        id: '/playlists',
                        label: '歌单',
                        icon: HyperIcon(Icons.queue_music),
                      ),
                      HyperSidebarItem(
                        id: '/albums',
                        label: '专辑',
                        icon: HyperIcon(Icons.album_outlined),
                      ),
                      HyperSidebarItem(
                        id: '/artists',
                        label: '歌手',
                        icon: HyperIcon(Icons.person_outline),
                      ),
                      HyperSidebarItem(
                        id: '/mvs',
                        label: 'MV',
                        icon: HyperIcon(Icons.music_video_outlined),
                      ),
                      HyperSidebarItem(
                        id: '/parse',
                        label: '导入歌单',
                        icon: HyperIcon(Icons.playlist_add),
                      ),
                      HyperSidebarItem(
                        id: '/settings',
                        label: '设置',
                        icon: HyperIcon(Icons.settings_outlined),
                      ),
                    ],
                  ),
                  Expanded(child: page),
                ],
              )
            : page,
      ),
      bottomBar: path == '/playing'
          ? null
          : const SafeArea(top: false, child: PlayerPage()),
    );
  }
}
