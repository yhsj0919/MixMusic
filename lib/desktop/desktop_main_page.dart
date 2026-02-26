import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:mix_music/page/app_playing/desktop_play_bar.dart';
import 'package:mix_music/route/routes.dart';
import 'package:mix_music/theme/theme_controller.dart';
import 'package:mix_music/theme/windows_controls.dart';

class DesktopMainPage extends StatefulWidget {
  const DesktopMainPage({
    super.key,
    required this.child,
    required this.shellContext,
    required this.state,
  });

  final Widget child;
  final BuildContext? shellContext;
  final GoRouterState state;

  @override
  State<DesktopMainPage> createState() => _DesktopMainPageState();
}

class _DesktopMainPageState extends State<DesktopMainPage> {
  var theme = Get.put(ThemeController());

  late final List<NavigationPaneItem> originalItems =
      [
        PaneItem(
          key: const ValueKey(Routes.home),
          icon: const WindowsIcon(WindowsIcons.home),
          title: const Text('首页'),
          body: const SizedBox.shrink(),
        ),
        PaneItem(
          key: const ValueKey(Routes.search),
          icon: const Icon(FluentIcons.search),
          title: const Text('搜索'),
          body: const SizedBox.shrink(),
        ),
        // PaneItemSeparator(),
        PaneItemHeader(
          header: Row(
            children: [
              Container(
                padding: EdgeInsets.only(left: 6, bottom: 6),
                child: Text('音乐'),
              ),
              Expanded(child: Container()),
              IconButton(
                icon: RotatedBox(
                  quarterTurns: 1, // 旋转 90°（1 表示顺时针旋转90°）
                  child: Icon(material.Icons.exit_to_app, size: 20),
                ),
                onPressed: () {
                  context.go(Routes.parsePlayList);
                },
              ),
            ],
          ),
        ),
        PaneItem(
          key: const ValueKey(Routes.recommend),
          icon: const Icon(FluentIcons.like),
          title: const Text('每日推荐'),
          body: const SizedBox.shrink(),
        ),
        PaneItem(
          key: const ValueKey(Routes.rank),
          icon: const Icon(FluentIcons.chart),
          title: const Text('排行'),
          body: const SizedBox.shrink(),
        ),
        PaneItem(
          key: const ValueKey(Routes.artist),
          icon: const Icon(FluentIcons.contact),
          title: const Text('歌手'),
          body: const SizedBox.shrink(),
        ),
        PaneItem(
          key: const ValueKey(Routes.playList),
          icon: const Icon(FluentIcons.playlist_music),
          title: const Text('歌单'),
          body: const SizedBox.shrink(),
        ),
        PaneItem(
          key: const ValueKey(Routes.album),
          icon: const Icon(WindowsIcons.music_album),
          title: const Text('专辑'),
          body: const SizedBox.shrink(),
        ),
        PaneItem(
          key: const ValueKey(Routes.mv),
          icon: const Icon(FluentIcons.my_movies_t_v),
          title: const Text('MV'),
          body: const SizedBox.shrink(),
        ),
        // PaneItem(key: const ValueKey('/song'), icon: const Icon(FluentIcons.music_note), title: const Text('新歌'), body: const SizedBox.shrink()),
        PaneItemSeparator(),
        PaneItem(
          key: const ValueKey(Routes.appHistoryMusicList),
          icon: const Icon(FluentIcons.history),
          title: const Text('历史'),
          body: const SizedBox.shrink(),
        ),
        PaneItem(
          key: const ValueKey(Routes.download),
          icon: const Icon(FluentIcons.download),
          title: const Text('下载'),
          body: const SizedBox.shrink(),
        ),
      ].map<NavigationPaneItem>((e) {
        PaneItem buildPaneItem(PaneItem item) {
          return PaneItem(
            key: item.key,
            icon: item.icon,
            title: item.title,
            body: item.body,
            onTap: () {
              final path = (item.key as ValueKey).value;
              if (GoRouterState.of(context).uri.toString() != path) {
                context.go(path);
              }
              item.onTap?.call();
            },
          );
        }

        if (e is PaneItemExpander) {
          return PaneItemExpander(
            key: e.key,
            icon: e.icon,
            title: e.title,
            body: e.body,
            items: e.items.map((item) {
              if (item is PaneItem) return buildPaneItem(item);
              return item;
            }).toList(),
          );
        }
        if (e is PaneItem) return buildPaneItem(e);
        return e;
      }).toList();
  late final List<NavigationPaneItem> footerItems = [
    PaneItemSeparator(),

    PaneItem(
      key: const ValueKey(Routes.setting),
      icon: const WindowsIcon(WindowsIcons.settings),
      title: const Text('设置'),
      trailing: IconButton(
        icon: Icon(FluentIcons.light, size: 20),
        onPressed: () {
          if (FluentTheme.of(context).brightness == Brightness.dark) {
            theme.themeMode.value = ThemeMode.light;
          } else {
            theme.themeMode.value = ThemeMode.dark;
          }
        },
      ),
      body: const SizedBox.shrink(),
      onTap: () {
        if (GoRouterState.of(context).uri.toString() != Routes.setting) {
          context.go(Routes.setting);
        }
      },
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Acrylic(
      tint: getColor(context).withValues(alpha: 0.8),

      child: Column(
        children: [
          Expanded(
            child: NavigationView(
              titleBar: TitleBar(
                isBackButtonVisible: false,
                // leading: context.canPop() ? IconButton(icon: const WindowsIcon(WindowsIcons.back), onPressed: () => context.pop()) : null,
                icon: null,
                title: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'MixMusic',
                    style: FluentTheme.of(context).typography.bodyLarge,
                  ),
                ),
                // automaticallyImplyLeading: false,
              ),
              paneBodyBuilder: (item, child) {
                final name = item?.key is ValueKey
                    ? (item!.key as ValueKey).value
                    : null;
                return FocusTraversalGroup(
                  key: ValueKey('body$name'),
                  child: widget.child,
                );
              },

              pane: NavigationPane(
                displayMode: PaneDisplayMode.expanded,
                size: NavigationPaneSize(openWidth: 250),
                selected: _calculateSelectedIndex(context),
                items: originalItems,
                footerItems: footerItems,
              ),
              // content: Container(child: Text("11111111111111111")),
            ),
          ),
          Divider(
            style: DividerThemeData(
              verticalMargin: const EdgeInsets.all(0),
              horizontalMargin: const EdgeInsets.all(0),
            ),
          ),
          Container(height: 118, child: DesktopPlayBar()),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    int indexOriginal = originalItems
        .where((item) => item.key != null)
        .toList()
        .indexWhere((item) => item.key == Key(location));

    if (indexOriginal == -1) {
      int indexFooter = footerItems
          .where((element) => element.key != null)
          .toList()
          .indexWhere((element) => element.key == Key(location));
      if (indexFooter == -1) {
        Future.delayed(Duration(milliseconds: 300)).then((v) {});
        return 0;
      }
      return originalItems
              .where((element) => element.key != null)
              .toList()
              .length +
          indexFooter;
    } else {
      return indexOriginal;
    }
  }
}
