import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/page/permission/permission_page.dart';
import 'package:mix_music/player/music_controller.dart';
import 'package:mix_music/route/routes.dart';
import 'package:mix_music/widgets/BlurRectWidget.dart';
import 'package:permission_handler/permission_handler.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  MusicController music = Get.put(MusicController());

  @override
  void initState() {
    super.initState();
    getPermission();
  }

  Future<int> getSystemVersion() async {
    if (Platform.isAndroid) {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

      return androidInfo.version.sdkInt;
    } else {
      return 32;
    }
  }

  Future<void> getPermission() async {
    getSystemVersion().then((value) async {
      if (value < 33) {
        if ((await Permission.storage.status) != PermissionStatus.granted) {
          Get.off(const PermissionPage());
          return Future(() => null);
        }
      }
      if (value >= 30) {
        if ((await Permission.manageExternalStorage.status) == PermissionStatus.granted) {
        } else {
          Get.off(const PermissionPage());
          return Future(() => null);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 0,
        leading: Container(width: 0),
        title: const Text("MixMusic"),
        actions: [
          IconButton(
              onPressed: () async {
                Get.toNamed(Routes.search, id: Routes.key);
              },
              icon: const Icon(Icons.search)),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                      onPressed: () {
                        Get.toNamed(Routes.rank, id: Routes.key);
                      },
                      icon: const Icon(Icons.align_vertical_top_rounded)),
                ],
              ),
            ),

            // Container(
            //   padding: const EdgeInsets.symmetric(horizontal: 16),
            //   alignment: Alignment.center,
            //   child: ClipRRect(
            //     borderRadius: const BorderRadius.all(Radius.circular(16)),
            //     child: CarouselSlider(
            //       options: CarouselOptions(
            //         autoPlay: true,
            //         aspectRatio: 16 / 6,
            //         viewportFraction: 1,
            //         enlargeCenterPage: true,
            //       ),
            //       items: [
            //         BlurRectWidget(
            //           color: Colors.grey.withOpacity(0.2),
            //           borderRadius: const BorderRadius.all(Radius.circular(16)),
            //         )
            //       ],
            //     ),
            //   ),
            // ),
            ListTile(
              title: const Text("歌单"),
              contentPadding: const EdgeInsets.only(left: 16),
              trailing: IconButton(
                onPressed: () {
                  Get.toNamed(Routes.playList, id: Routes.key);
                },
                icon: Icon(
                  Icons.keyboard_arrow_right_outlined,
                  color: Theme.of(context).iconTheme.color,
                ),
              ),
            ),
            Container(
              height: 80,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                physics: const BouncingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                children: [
                  BlurRectWidget(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                    width: 80,
                    margin: EdgeInsets.only(right: 8),
                  ),
                  BlurRectWidget(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                    width: 80,
                    margin: EdgeInsets.only(right: 8),
                  ),
                  BlurRectWidget(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                    width: 80,
                    margin: EdgeInsets.only(right: 8),
                  ),
                  BlurRectWidget(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                    width: 80,
                    margin: EdgeInsets.only(right: 8),
                  ),
                ],
              ),
            ),
            ListTile(
              title: const Text("专辑"),
              contentPadding: const EdgeInsets.only(left: 16),
              trailing: IconButton(
                onPressed: () {
                  Get.toNamed(Routes.album, id: Routes.key);
                },
                icon: Icon(
                  Icons.keyboard_arrow_right_outlined,
                  color: Theme.of(context).iconTheme.color,
                ),
              ),
            ),
            Container(
              height: 80,
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                physics: const BouncingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                children: [
                  BlurRectWidget(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                    width: 80,
                    margin: EdgeInsets.only(right: 8),
                  ),
                  BlurRectWidget(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                    width: 80,
                    margin: EdgeInsets.only(right: 8),
                  ),
                  BlurRectWidget(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                    width: 80,
                    margin: EdgeInsets.only(right: 8),
                  ),
                  BlurRectWidget(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                    width: 80,
                    margin: EdgeInsets.only(right: 8),
                  ),
                ],
              ),
            ),
            ListTile(
              title: const Text("新歌"),
              contentPadding: const EdgeInsets.only(left: 16),
              trailing: IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.keyboard_arrow_right_outlined,
                  color: Theme.of(context).iconTheme.color,
                ),
              ),
            ),
            ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: 10,
              shrinkWrap: true,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  leading: BlurRectWidget(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    width: 45,
                    height: 45,
                  ),
                  title: Text("歌名$index"),
                  subtitle: Text("歌手"),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
