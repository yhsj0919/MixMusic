import 'package:fluent_ui/fluent_ui.dart';
import 'package:mix_music/common/api/api_factory.dart';
import 'package:mix_music/common/entity/plugins_info.dart';
import 'package:mix_music/page/playlist/desktop/desktop_playlist_tab_page.dart';
import 'package:mix_music/route/routes.dart';
import 'package:mix_music/widgets/app_image.dart';

class DesktopPlayListPage extends StatefulWidget {
  const DesktopPlayListPage({super.key});

  @override
  _DesktopPlayListPageState createState() => _DesktopPlayListPageState();
}

class _DesktopPlayListPageState extends State<DesktopPlayListPage> with TickerProviderStateMixin {
  PlayListPageController controller = PlayListPageController();
  FlyoutController typeController = FlyoutController();

  List<PluginsInfo> plugins = [];

  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    plugins = ApiFactory.getPlayListPlugins();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(title: Text('歌单')),
      content: TabView(
        header: Container(),
        tabs: plugins.map((plugin) {
          return Tab(
            text: Text(plugin.name ?? ""),
            selectedBackgroundColor: WidgetStateProperty.all((FluentTheme.of(context).brightness == Brightness.light ? Colors.black : Colors.white).withValues(alpha: 0.1)),
            icon: AppImage(url: plugin.icon ?? "", width: 16, height: 16),
            body: DesktopPlayListTabPage(plugin: plugin, controller: controller),
          );
        }).toList(),
        currentIndex: currentIndex,
        onChanged: (index) => setState(() => currentIndex = index),
        tabWidthBehavior: TabWidthBehavior.sizeToContent,
        closeButtonVisibility: CloseButtonVisibilityMode.always,
        showScrollButtons: true,
        footer: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: FlyoutTarget(
            controller: typeController,
            child: IconButton(
              icon: Icon(FluentIcons.filter, size: 16),
              onPressed: () {
                controller.open(plugins[currentIndex].package, typeController);
              },
            ),
          ),
        ),
      ),
    );
  }
}
