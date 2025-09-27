import 'package:fluent_ui/fluent_ui.dart';
import 'package:mix_music/common/api/api_factory.dart';
import 'package:mix_music/common/entity/plugins_info.dart';
import 'package:mix_music/widgets/app_image.dart';

import 'desktop_artist_tab_page.dart';

class DesktopArtistPage extends StatefulWidget {
  const DesktopArtistPage({super.key});

  @override
  _DesktopArtistPageState createState() => _DesktopArtistPageState();
}

class _DesktopArtistPageState extends State<DesktopArtistPage> with TickerProviderStateMixin {
  ArtistController controller = ArtistController();
  FlyoutController typeController = FlyoutController();

  int currentIndex = 0;

  List<PluginsInfo> plugins = [];

  @override
  void initState() {
    super.initState();
    plugins = ApiFactory.getArtistPlugins();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(title: Text('歌手')),
      content: TabView(
        header: Container(),
        tabs: plugins.map((plugin) {
          return Tab(
            text: Text(plugin.name ?? ""),
            selectedBackgroundColor: WidgetStateProperty.all((FluentTheme.of(context).brightness == Brightness.light ? Colors.black : Colors.white).withValues(alpha: 0.1)),
            icon: AppImage(url: plugin.icon ?? "", width: 16, height: 16),
            body: DesktopArtistTabPage(plugin: plugin, controller: controller),
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
