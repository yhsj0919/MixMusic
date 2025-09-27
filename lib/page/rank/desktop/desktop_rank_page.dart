import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:mix_music/common/api/api_factory.dart';
import 'package:mix_music/common/entity/plugins_info.dart';
import 'package:mix_music/page/app_playing/play_bar.dart';
import 'package:mix_music/page/rank/desktop/desktop_rank_tab_page.dart';
import 'package:mix_music/widgets/app_image.dart';

class DesktopRankPage extends StatefulWidget {
  const DesktopRankPage({super.key});

  @override
  _DesktopRankPageState createState() => _DesktopRankPageState();
}

class _DesktopRankPageState extends State<DesktopRankPage> with TickerProviderStateMixin {
  RankPageController controller = RankPageController();

  List<PluginsInfo> plugins = [];
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    plugins = ApiFactory.getRankPlugins();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(title: Text('排行榜')),
      content: TabView(
        header: Container(),
        tabs: plugins.map((plugin) {
          return Tab(
            text: Text(plugin.name ?? ""),
            selectedBackgroundColor: WidgetStateProperty.all((FluentTheme.of(context).brightness == Brightness.light ? Colors.black : Colors.white).withValues(alpha: 0.1)),
            icon: AppImage(url: plugin.icon ?? "", width: 16, height: 16),
            body: DesktopRankTabPage(plugin: plugin, controller: controller),
          );
        }).toList(),
        currentIndex: currentIndex,
        onChanged: (index) => setState(() => currentIndex = index),
        tabWidthBehavior: TabWidthBehavior.sizeToContent,
        closeButtonVisibility: CloseButtonVisibilityMode.always,
        showScrollButtons: true,
      ),
    );
  }
}
