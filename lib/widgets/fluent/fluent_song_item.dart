import 'package:fluent_ui/fluent_ui.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:mix_music/common/api/api_factory.dart';
import 'package:mix_music/common/entity/mix_song.dart';
import 'package:mix_music/page/mv/desktop/desptop_mv_detail_page.dart';
import 'package:mix_music/player/music_controller.dart';
import 'package:mix_music/route/routes.dart';
import 'package:mix_music/widgets/app_image.dart';
import 'package:mix_music/widgets/mix_site_item.dart';

class FluentSongItem extends StatelessWidget {
  FluentSongItem({super.key, required this.song, required this.index, this.onTap, this.showSite = false});

  final MixSong song;
  final int index;
  final bool showSite;
  final GestureTapCallback? onTap;

  final MusicController music = Get.put(MusicController());

  @override
  Widget build(BuildContext context) {
    var plugin = ApiFactory.getPlugin(song.package);
    return Obx(
          () =>
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 3),
            decoration: BoxDecoration(
              color: index % 2 == 0 ? Colors.white.withAlpha((255 * (FluentTheme
                  .of(context)
                  .brightness == Brightness.light ? 1 : 0.1)).toInt()) : null,
              border: index % 2 == 0
                  ? Border.all(
                color: Color(0x11333333), // 边框颜色
                width: 1, // 边框宽度
              )
                  : null,
              borderRadius: BorderRadius.circular(6.0), // 圆角半径
            ),
            child: ListTile.selectable(
              contentPadding: EdgeInsetsGeometry.zero,
              selected: music.currentMusic.value?.id.toString() == song.id.toString(),
              leading: Container(
                width: 34,
                height: 34,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    AppImage(url: song.pic ?? "",
                        width: 34,
                        height: 34,
                        radius: 4,
                        fit: BoxFit.cover),
                    if (showSite)
                      ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        child: Container(
                          color: Colors.white,
                          child: AppImage(url: plugin?.icon ?? "", width: 12, height: 12),
                        ),
                      ),
                  ],
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(song.title ?? "", maxLines: 1, overflow: TextOverflow.ellipsis, style: FluentTheme
                              .of(context)
                              .typography
                              .body),
                        ),
                        song.vip == 1
                            ? Container(
                          alignment: Alignment.center,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.all(Radius.circular(4.0)),
                            border: Border.all(width: 1, color: Colors.green),
                          ),
                          child: Text("VIP", maxLines: 1, style: TextStyle(fontSize: 10, color: Colors.green)),
                        )
                            : Container(),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Center(
                      child: IconButton(
                        icon: Text(song.artist?.firstOrNull?.title ?? "", maxLines: 1, overflow: TextOverflow.ellipsis, style: FluentTheme
                            .of(context)
                            .typography
                            .body),
                        onPressed: song.artist?.firstOrNull?.id != null
                            ? () {
                          context.push(Routes.artistDetail, extra: song.artist?.firstOrNull);
                        }
                            : null,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Center(
                      child: IconButton(
                        icon: Text(song.album?.title ?? "", maxLines: 1, overflow: TextOverflow.ellipsis, style: FluentTheme
                            .of(context)
                            .typography
                            .body),
                        onPressed: song.album?.id != null
                            ? () {
                          context.push(Routes.albumDetail, extra: song.album);
                        }
                            : null,
                      ),
                    ),
                  ),
                  Expanded(child: Container()),
                ],
              ),

              // subtitle: Text(song.subTitle ?? "", overflow: TextOverflow.ellipsis, maxLines: 1),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  song.mv != null
                      ? IconButton(
                    onPressed: () {
                      Navigator.of(context, rootNavigator: true).push(FluentPageRoute(builder: (context) => DesktopMvDetailPage(item: song.mv!)));
                    },
                    icon: Icon(FluentIcons.video),
                  )
                      : Container(width: 24, height: 24),
                  IconButton(
                    onPressed: () {
                      // showBottomDownload(context, song);
                    },
                    icon: Icon(FluentIcons.more),
                  ),
                ],
              ),
              onPressed: onTap,
            ),
          ),
    );
  }

// void showBottomDownload(BuildContext context, MixSong song) {
//   showModalBottomSheet(
//       context: context,
//       showDragHandle: true,
//       useSafeArea: true,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16.0), // 设置圆角的大小
//       ),
//       scrollControlDisabledMaxHeightRatio: 1 / 2,
//       builder: (BuildContext context) {
//         return AppDownloadTypePage(
//           song: song,
//           onTap: () {
//             Navigator.of(context).pop();
//           },
//         );
//       }).then((value) {});
// }
}
