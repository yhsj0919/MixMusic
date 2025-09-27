import 'package:fluent_ui/fluent_ui.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:mix_music/common/api/api_factory.dart';
import 'package:mix_music/common/entity/plugins_info.dart';
import 'package:mix_music/constant.dart';
import 'package:mix_music/page/home/home_controller.dart';
import 'package:mix_music/theme/theme_controller.dart';
import 'package:mix_music/utils/db.dart';
import 'package:mix_music/widgets/app_image.dart';
import 'package:mix_music/widgets/fluent/fluent_group.dart';
import 'package:mix_music/widgets/fluent/fluent_list_tile.dart';
import 'package:mix_music/widgets/hyper/hyper_background.dart';
import 'package:mix_music/widgets/hyper/hyper_group.dart';
import 'package:mix_music/widgets/hyper/hyper_leading.dart';

class DesktopHomeSitePage extends StatefulWidget {
  const DesktopHomeSitePage({super.key});

  @override
  State<DesktopHomeSitePage> createState() => _DesktopHomeSitePageState();
}

class _DesktopHomeSitePageState extends State<DesktopHomeSitePage> {
  HomeController home = Get.put(HomeController());
  RxList<PluginsInfo> plugins = RxList();
  RxnString homeSite = RxnString();
  ThemeController theme = Get.put(ThemeController());

  @override
  void initState() {
    super.initState();
    plugins.value = ApiFactory.getRecPlugins();
    homeSite.value = AppDB.getString(Constant.KEY_HOME_SITE);
  }

  @override
  Widget build(BuildContext context) {
    double bottom = MediaQuery.of(context).padding.bottom;

    return ScaffoldPage(
      header: PageHeader(
        title: Text("首页数据"),
        leading: Padding(
          padding: EdgeInsetsGeometry.symmetric(horizontal: 12),
          child: IconButton(
            icon: Icon(FluentIcons.back),
            onPressed: () {
              context.pop();
            },
          ),
        ),
      ),
      content: Obx(
        () => CustomScrollView(
          slivers: [
            FluentGroup(
              title: Text("下列站点可展示在首页"),
              children: [
                ListView.builder(
                  padding: EdgeInsets.all(0),
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: plugins.length,
                  itemBuilder: (BuildContext context, int index) {
                    var plugin = plugins[index];
                    return Obx(
                      () => Container(
                        margin: EdgeInsets.symmetric(vertical: 2),
                        decoration: BoxDecoration(
                          color: FluentTheme.of(context).scaffoldBackgroundColor,
                          border: Border.all(
                            color: Colors.black.withAlpha((255 * 0.1).toInt()), // 边框颜色
                            width: 1, // 边框宽度
                          ),
                          borderRadius: BorderRadius.circular(5), // 圆角半径
                        ),
                        child: ListTile.selectable(
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          margin: EdgeInsets.zero,
                          leading: Padding(padding: EdgeInsetsGeometry.symmetric(vertical: 10),child: AppImage(url: '${plugin.icon}', width: 30, height: 30),),
                          title: Text(plugin.name ?? ""),
                          subtitle: Text(plugin.version ?? ""),
                          selected: plugin.package?.contains(homeSite.value ?? "") == true,
                          onPressed: () {
                            AppDB.setString(Constant.KEY_HOME_SITE, plugin.package ?? "");
                            homeSite.value = plugin.package;
                            home.getData();
                            theme.refreshMainColor();
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            SliverGap(bottom + 16),
          ],
        ),
      ),
    );
  }
}
