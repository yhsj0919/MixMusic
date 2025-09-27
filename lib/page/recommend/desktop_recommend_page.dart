import 'package:fluent_ui/fluent_ui.dart';
import 'package:mix_music/common/api/api_factory.dart';
import 'package:mix_music/common/entity/plugins_info.dart';
import 'package:mix_music/page/recommend/desktop_recommend_tab_page.dart';
import 'package:mix_music/widgets/app_image.dart';

class DesktopRecommendPage extends StatefulWidget {
  const DesktopRecommendPage({super.key});

  @override
  _DesktopRecommendPageState createState() => _DesktopRecommendPageState();
}

class _DesktopRecommendPageState extends State<DesktopRecommendPage> with TickerProviderStateMixin {
  List<PluginsInfo> plugins = [];
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    plugins = ApiFactory.getRecommendPlugins();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(title: Text('每日推荐')),
      content: TabView(
        header: Container(),
        tabs: plugins.map((plugin) {
          return Tab(
            text: Text(plugin.name ?? ""),
            selectedBackgroundColor: WidgetStateProperty.all((FluentTheme.of(context).brightness == Brightness.light ? Colors.black : Colors.white).withValues(alpha: 0.1)),
            icon: AppImage(url: plugin.icon ?? "", width: 16, height: 16),
            body: DesktopRecommendTabPage(plugin: plugin),
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
