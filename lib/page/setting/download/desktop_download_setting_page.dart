import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:mix_music/constant.dart';
import 'package:mix_music/utils/db.dart';
import 'package:mix_music/widgets/fluent/fluent_group.dart';
import 'package:mix_music/widgets/fluent/fluent_list_tile.dart';
import 'package:mix_music/widgets/hyper/hyper_trailing.dart';

class DesktopDownloadSettingPage extends StatefulWidget {
  const DesktopDownloadSettingPage({super.key});

  @override
  State<DesktopDownloadSettingPage> createState() => _DesktopDownloadSettingPageState();
}

class _DesktopDownloadSettingPageState extends State<DesktopDownloadSettingPage> {
  RxnString downloadFolder = RxnString(null);
  RxInt downloadName = RxInt(0);
  Rx<bool> storageStatus = Rx(false);
  Rx<bool> manageStatus = Rx(false);

  @override
  void initState() {
    super.initState();
    downloadFolder.value = AppDB.getString(Constant.KEY_DOWNLOAD_FOLDER);
    downloadName.value = AppDB.getInt(Constant.KEY_DOWNLOAD_NAME) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
        title: Text('下载设置'),
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
      content: CustomScrollView(
        slivers: [
          FluentGroup(
            title: Text("保存目录"),
            children: [
              Obx(
                () => FluentListTile(
                  // leading: HyperIcon(color: Colors.blue, icon: Icons.folder_rounded),
                  title: "下载目录",
                  subtitle: downloadFolder.value ?? "暂无设置",
                  trailing: HyperTrailing(),
                  onTap: () async {
                    var result = await FilePicker.getDirectoryPath(dialogTitle: "选择目录", lockParentWindow: true);
                    if (result != null) {
                      downloadFolder.value = result;
                      AppDB.setString(Constant.KEY_DOWNLOAD_FOLDER, result);
                    }
                  },
                ),
              ),
            ],
          ),
          SliverGap(12),
          Obx(
            () => FluentGroup(
              title: Text("命名方式"),
              children: [
                Container(
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
                    title: Text("歌曲名"),
                    selected: downloadName.value == 0,
                    onPressed: () {
                      AppDB.setInt(Constant.KEY_DOWNLOAD_NAME, 0);
                      downloadName.value = 0;
                    },
                  ),
                ),
                Container(
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
                    title: Text("歌曲名-歌手"),
                    selected: downloadName.value == 1,
                    onPressed: () {
                      AppDB.setInt(Constant.KEY_DOWNLOAD_NAME, 1);
                      downloadName.value = 1;
                    },
                  ),
                ),
                Container(
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
                    title: Text("歌手-歌曲名"),
                    selected: downloadName.value == 2,
                    onPressed: () {
                      AppDB.setInt(Constant.KEY_DOWNLOAD_NAME, 2);
                      downloadName.value = 2;
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
