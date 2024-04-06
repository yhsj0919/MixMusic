import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/page/api_controller.dart';
import 'package:mix_music/page/app_playing/app_playing_page.dart';
import 'package:mix_music/page/app_playlist/app_playlist_page.dart';
import 'package:mix_music/page/mine/mine_page.dart';
import 'package:mix_music/page/play_bar.dart';
import 'package:mix_music/player/music_controller.dart';
import 'package:mix_music/route/routes.dart';
import 'package:mix_music/widgets/sliding_up_panel.dart';

import 'app_controller.dart';

class AppMainPage extends StatefulWidget {
  AppMainPage({super.key});

  @override
  State<AppMainPage> createState() => _AppMainPageState();
}

class _AppMainPageState extends State<AppMainPage> {
  var app = Get.put(AppController());

  var music = Get.put(MusicController());

  PageController pageController = PageController();

  @override
  Widget build(BuildContext context) {
    app.maxHeight.value = MediaQuery.of(context).size.height;
    app.maxWidth.value = MediaQuery.of(context).size.width;

    return WillPopScope(
        onWillPop: () async {
          if (Get.global(Routes.key).currentState?.canPop() == true) {
            Get.back(id: Routes.key);
          } else {
            return false;
          }
          return false;
          // 返回true表示允许退出当前页面
        },
        child: Scaffold(
          endDrawerEnableOpenDragGesture: false,
          endDrawer: Container(
            margin: const EdgeInsets.all(16), // 调整Drawer的外边距
            child: Drawer(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16.0)),
              ),
              child: AppPlayListPage(inPanel: false),
            ),
          ),
          body: Row(
            children: [
              context.isLandscape
                  ? Obx(() => AnimatedContainer(
                      width: 80 - 80 * app.position.value,
                      height: double.infinity,
                      duration: const Duration(milliseconds: 0),
                      child: app.position.value > 0
                          ? Container()
                          : NavigationRail(
                              destinations: const [
                                NavigationRailDestination(icon: Icon(Icons.home_filled), label: Text("首页")),
                                NavigationRailDestination(icon: Icon(Icons.person), label: Text("我的")),
                              ],
                              selectedIndex: app.navBarIndex.value,
                              onDestinationSelected: (index) {
                                app.navBarIndex.value = index;
                                pageController.animateToPage(
                                  index,
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeInOut,
                                );
                              },
                            )))
                  : Container(),
              Expanded(
                  child: Obx(() => PageView(
                        controller: pageController,
                        physics: (app.showNav.value && app.position.value == 0) ? null : const NeverScrollableScrollPhysics(),
                        onPageChanged: (index) {
                          app.navBarIndex.value = index;
                        },
                        children: [
                          buildMain(),
                          const MinePage(),
                        ],
                      )))
            ],
          ),
          bottomNavigationBar: !context.isLandscape
              ? Obx(
                  () => app.showNav.value
                      ? AnimatedContainer(
                          height: 60 - 60 * app.position.value,
                          duration: const Duration(milliseconds: 0),
                          child: app.position.value > 0
                              ? Container()
                              : NavigationBar(
                                  selectedIndex: app.navBarIndex.value,
                                  onDestinationSelected: (index) {
                                    app.navBarIndex.value = index;
                                    pageController.animateToPage(
                                      index,
                                      duration: const Duration(milliseconds: 400),
                                      curve: Curves.easeInOut,
                                    );
                                  },
                                  destinations: const [
                                    NavigationDestination(icon: Icon(Icons.home_filled), label: "首页"),
                                    NavigationDestination(icon: Icon(Icons.person), label: "我的"),
                                  ],
                                ),
                        )
                      : Container(height: 0),
                )
              : null,
        ));
  }

  Widget buildMain() {
    return Obx(
      () => SlidingUpPanel(
        backdropEnabled: true,
        backdropTapClosesPanel: true,
        // bottomOffset: (context.isPortrait && app.showPlayBar.value) ? 60 : 0,
        isDraggable: music.currentMusic.value != null,
        controller: app.panelController,
        scrollController: app.panelScrollController,
        onPanelSlide: (pp) {
          app.position.value = pp;
          if (pp == 0) {
            app.panelController.tempDisableSlide(false);
            app.type.value = 0;
          }
        },
        maxHeight: app.type.value == 0 ? app.maxHeight.value : app.maxHeight.value / 4 * 3,
        renderPanelSheet: false,
        panelBuilder: () {
          if (app.type.value == 0) {
            return _playingPage();
          } else {
            return _playList();
          }
        },
        collapsed: (app.showPlayBar.value && music.currentMusic.value != null)
            ? Visibility(
                //这里解决播放条和播放页重叠导致的点击失效
                visible: app.position.value < 0.5,
                child: const PlayBar(),
              )
            : null,
        body: Navigator(
          key: Get.nestedKey(Routes.key),
          initialRoute: Routes.home,
          reportsRouteUpdateToEngine: true,
          observers: [RouteObserver()],
          onGenerateRoute: (setting) {
            app.currentRoute.value = setting.name;
            return Routes.getRoute(setting);
          },
        ),
      ),
    );
  }

  Widget _playingPage() {
    var app = Get.put(AppController());
    return Obx(
      () => Opacity(
        opacity: (app.position.value * 3 > 1) ? 1 : (app.position.value * 3),
        child: AppPlayingPage(),
      ),
    );
  }

  Widget _playList() {
    return Obx(
      () => Opacity(
        opacity: app.position.value,
        child: Center(child: Builder(
          builder: (BuildContext context) {
            return Container(
              constraints: const BoxConstraints(maxWidth: 640),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.all(Radius.circular(16 - (app.type.value == 0 ? 16 * app.position.value : 0))),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 12.0,
                    color: Theme.of(context).shadowColor.withOpacity(0.5),
                  ),
                ],
              ),
              margin: EdgeInsets.all(16 - (app.type.value == 0 ? 16 * app.position.value : 0)),
              child: AppPlayListPage(inPanel: true),
            );
          },
        )),
      ),
    );
  }
}

class RouteObserver extends NavigatorObserver {
  AppController app = Get.put(AppController());

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    app.currentRoute.value = route.settings.name;
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    app.currentRoute.value = previousRoute?.settings.name;
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    print('Route replaced: ${oldRoute?.settings.name} with ${newRoute?.settings.name}');
    print('Route replaced: ${oldRoute?.settings.name}');

    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}

class AppBinding implements Bindings {
  @override
  void dependencies() {
    Get.put(AppController());
    Get.put(ApiController());
    Get.put(MusicController());
  }
}
