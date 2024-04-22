// import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
// import 'package:audioplayers/audioplayers.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:mix_music/widgets/app_image.dart';
//
// import '../player/music_controller.dart';
// import '../widgets/BlurRectWidget.dart';
//
// class PlayBar extends StatefulWidget {
//   const PlayBar({super.key});
//
//   @override
//   State<PlayBar> createState() => _PlayBarState();
// }
//
// class _PlayBarState extends State<PlayBar> {
//   MusicController controller = Get.put(MusicController());
//   RxBool imgHover = RxBool(false);
//
//   @override
//   Widget build(BuildContext context) {
//     return Material(
//       color: Colors.transparent,
//       child: BlurRectWidget(
//         height: 65,
//         margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//         padding: const EdgeInsets.symmetric(horizontal: 8),
//         borderRadius: const BorderRadius.all(Radius.circular(16)),
//         child: Row(
//           children: [
//             InkWell(
//               onHover: controller.currentMusic.value != null
//                   ? (hover) {
//                       imgHover.value = hover;
//                     }
//                   : null,
//               onTap: controller.currentMusic.value != null
//                   ? () {
//                     }
//                   : null,
//               child: Obx(() => Stack(
//                     children: [
//                       AppImage(url: controller.currentMusic.value?.pic?.toString() ?? ""),
//                       AnimatedOpacity(
//                         opacity: imgHover.value ? 1.0 : 0.0,
//                         duration: const Duration(milliseconds: 300),
//                         child: BlurRectWidget(
//                           width: 50,
//                           height: 50,
//                           borderRadius: const BorderRadius.all(Radius.circular(8)),
//                           child: Transform.rotate(
//                             angle: 90 * (3.14 / 180), // 将角度转换为弧度
//                             child: Icon(
//                               Icons.arrow_back_ios_rounded,
//                               color: Theme.of(context).iconTheme.color,
//                             ), // 要旋转的控件
//                           ),
//                         ),
//                       ),
//                     ],
//                   )),
//             ),
//             const SizedBox(width: 8),
//             Flexible(
//               child: InkWell(
//                 hoverColor: Colors.transparent,
//                 splashColor: Colors.transparent,
//                 highlightColor: Colors.transparent,
//                 onTap: () {
//                 },
//                 child: Obx(
//                   () => Column(
//                     mainAxisSize: MainAxisSize.min,
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           Expanded(child: Text(controller.currentMusic.value?.title ?? "N/A", style: const TextStyle(fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis)),
//                           Container(width: 8),
//                           // const Icon(Icons.favorite_outlined, size: 20, color: Colors.red),
//                         ],
//                       ),
//                       Text(controller.currentMusic.value?.artist?.map((e) => e.name).join(",") ?? "N/A",
//                           style: const TextStyle(fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//             context.isPhone
//                 ? Container()
//                 : Expanded(
//                     flex: 2,
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 16),
//                       child: Obx(
//                         () => ProgressBar(
//                           progress: controller.position.value ?? const Duration(),
//                           // buffered: const Duration(milliseconds: 2000),
//                           total: controller.duration.value ?? const Duration(),
//                           timeLabelLocation: TimeLabelLocation.sides,
//                           timeLabelTextStyle: Theme.of(context).textTheme.bodyMedium,
//                           onSeek: (duration) {
//                             controller.seek(duration);
//                           },
//                         ),
//                       ),
//                     ),
//                   ),
//             context.isPhone ? Container() : const SizedBox(width: 16),
//             context.isPhone
//                 ? Container()
//                 : IconButton(
//                     icon: const Icon(Icons.skip_previous_rounded),
//                     onPressed: () {
//                       controller.previous();
//                     },
//                   ),
//             const SizedBox(width: 16),
//             playButton(context),
//             context.isPhone ? Container() : const SizedBox(width: 16),
//             context.isPhone
//                 ? Container()
//                 : IconButton(
//                     icon: const Icon(Icons.skip_next_rounded),
//                     onPressed: () {
//                       controller.next();
//                     },
//                   ),
//             IconButton(
//               icon: const Icon(Icons.queue_music_outlined),
//               onPressed: () {
//                 if (!context.isPhone) {
//                   Scaffold.of(context).openEndDrawer();
//                 } else {
//
//                 }
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   ///播放按钮
//   Widget playButton(BuildContext context) {
//     return IconButton(
//       iconSize: 30,
//       onPressed: () {
//         controller.playOrPause();
//       },
//       icon: Stack(
//         alignment: Alignment.center,
//         children: [
//           Obx(() => controller.isBuffering.value
//               ? CircularProgressIndicator(
//                   strokeWidth: 2,
//                   backgroundColor: Theme.of(context).brightness == Brightness.light ? Colors.black12 : Colors.white12,
//                 )
//               : CircularProgressIndicator(
//                   value: (controller.position.value?.inMilliseconds ?? 0) / (controller.duration.value?.inMilliseconds ?? 1),
//                   strokeWidth: 1,
//                   backgroundColor: Theme.of(context).brightness == Brightness.light ? Colors.black12 : Colors.white12,
//                 )),
//           Obx(() => Icon(controller.state.value == PlayerState.playing ? Icons.pause_rounded : Icons.play_arrow_rounded)),
//         ],
//       ),
//     );
//   }
// }
