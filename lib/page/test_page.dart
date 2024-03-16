import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/widgets/sliding_up_panel.dart';

const Set<PointerDeviceKind> _kTouchLikeDeviceTypes = <PointerDeviceKind>{
  PointerDeviceKind.touch,
  PointerDeviceKind.mouse,
  PointerDeviceKind.stylus,
  PointerDeviceKind.invertedStylus,
  PointerDeviceKind.unknown
};

void main() {
  runApp(const SlidingBoxExampleApp());
}

class SlidingBoxExampleApp extends StatelessWidget {
  const SlidingBoxExampleApp({super.key});

  static const ThemeMode themeMode = ThemeMode.dark;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      scrollBehavior: MaterialScrollBehavior().copyWith(scrollbars: true, dragDevices: _kTouchLikeDeviceTypes),
      title: "测试",
      home: TestPage(),
    );
  }
}

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  RxDouble position = RxDouble(0);
  RxDouble maxHeight = RxDouble(0);
  RxDouble maxWidth = RxDouble(0);
  RxInt type = RxInt(0);
  PanelController panelController = PanelController();
  ScrollController scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    maxHeight.value = MediaQuery.of(context).size.height;
    maxWidth.value = MediaQuery.of(context).size.width;

    return Material(
      child: Obx(() => SlidingUpPanel(
            controller: panelController,
            scrollController: scrollController,
            onPanelSlide: (pp) {
              position.value = pp;
              if (pp == 0) {
                type.value = 0;
              }
            },
            maxHeight: type.value == 0 ? maxHeight.value : maxHeight.value / 4 * 3,
            renderPanelSheet: false,
            panelBuilder: () {
              if (type.value == 0) {
                return _floatingPanel();
              } else {
                return _scrollingList();
              }
            },
            collapsed: _floatingCollapsed(),
            body: Scaffold(
              appBar: AppBar(
                title: const Text("测试页面"),
              ),
              body: PageView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 8,
                itemBuilder: (BuildContext context, int index) {
                  return Center(
                    child: Text("data$index"),
                  );
                },
              ),
            ),
          )),
    );
  }

  Widget _floatingCollapsed() {
    return Obx(
      () => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(16 - 16 * position.value)),
          boxShadow: const [
            BoxShadow(
              blurRadius: 12.0,
              color: Colors.black12,
            ),
          ],
        ),
        margin: EdgeInsets.all(16 - 16 * position.value),
        child: Row(
          children: [
            Expanded(
              child: PageView.builder(
                allowImplicitScrolling: true,
                scrollDirection: Axis.horizontal,
                itemCount: 8,
                itemBuilder: (BuildContext context, int index) {
                  return Center(child: Text("Data$index"));
                },
              ),
            ),
            IconButton(
                onPressed: () {
                  type.value = 0;
                },
                icon: const Icon(Icons.play_arrow_rounded)),
            IconButton(
              onPressed: () {
                type.value = 1;
                panelController.open();
              },
              icon: const Icon(Icons.list_alt_rounded),
            )
          ],
        ),
      ),
    );
  }

  Widget _floatingPanel() {
    return Obx(
      () => Opacity(
        opacity: position.value,
        child: Scaffold(
          onEndDrawerChanged: (ch) {
            panelController.tempDisableSlide(ch);
          },
          endDrawer: Container(
            margin: const EdgeInsets.all(16), // 调整Drawer的外边距
            child: Drawer(
              backgroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16.0)),
              ),
              child: ListView.builder(
                itemCount: 50,
                itemBuilder: (BuildContext context, int i) {
                  return Container(
                    padding: const EdgeInsets.all(12.0),
                    child: Text("$i"),
                  );
                },
              ),
            ),
          ),
          body: Builder(
            builder: (BuildContext context) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.yellow,
                  borderRadius: BorderRadius.all(Radius.circular(16 - (type.value == 0 ? 16 * position.value : 0))),
                ),
                // decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(24.0)), boxShadow: [
                //   BoxShadow(
                //     blurRadius: 20.0,
                //     color: Colors.grey,
                //   ),
                // ]),
                margin: EdgeInsets.all(16 - (type.value == 0 ? 16 * position.value : 0)),
                child: Center(
                  child: TextButton(
                    onPressed: () {
                      Scaffold.of(context).openEndDrawer();
                    },
                    child: const Text("打开列表"),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _scrollingList() {
    return Obx(
      () => Opacity(
        opacity: position.value,
        child: Center(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(16 - (type.value == 0 ? 16 * position.value : 0))),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 12.0,
                  color: Colors.black12,
                ),
              ],
            ),
            margin: EdgeInsets.all(16 - (type.value == 0 ? 16 * position.value : 0)),
            child: ListView.builder(
              controller: scrollController,
              itemCount: 50,
              itemBuilder: (BuildContext context, int i) {
                return Container(
                  padding: const EdgeInsets.all(12.0),
                  child: Text("$i"),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
