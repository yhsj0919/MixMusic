import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:mix_music/widgets/hyper/hyper_group.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> with TickerProviderStateMixin {
  late TabController tabController;
  final double bottomBarHeight = 46;
  var items = ["关于", "赞赏"];

  @override
  void initState() {
    super.initState();

    tabController = TabController(length: items.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final double pinnedHeaderHeight = 62 + bottomBarHeight;

    return Scaffold(
      body: ExtendedNestedScrollView(
        pinnedHeaderSliverHeightBuilder: () {
          return pinnedHeaderHeight;
        },
        onlyOneScrollInBody: true,
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [
            SliverAppBar.large(
              title: Text('MixMusic'),
              forceElevated: innerBoxIsScrolled,
              // toolbarHeight: 62,
            ),
            PinnedHeaderSliver(
              child: Container(
                width: double.infinity,
                height: bottomBarHeight,
                color: Theme.of(context).colorScheme.surface,
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: TabBar(
                  dividerHeight: 0,
                  tabAlignment: TabAlignment.start,
                  indicator: BoxDecoration(
                    color: Colors.white, // 指示器的背景颜色
                    borderRadius: BorderRadius.circular(8),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  // 控制指示器的宽度是否和标签文字一样宽
                  indicatorPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  isScrollable: true,
                  controller: tabController,
                  overlayColor: WidgetStateProperty.resolveWith<Color>((states) {
                    // 当标签被点击时，显示半透明的蓝色背景
                    if (states.contains(WidgetState.selected)) {
                      return Colors.transparent; // 设置选中时的覆盖颜色
                    }
                    return Colors.transparent; // 未选中时，覆盖层是透明的
                  }),
                  tabs: items
                      .map((item) => Tab(
                            text: item,
                          ))
                      .toList(),
                ),
              ),
            )
          ];
        },
        body: TabBarView(
          controller: tabController,
          children: [
            ListView(
              children: [
                HyperGroup(
                  inSliver: false,
                  children: [
                    Container(
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      child: Text("👏你好，很高兴认识你！"),
                    )
                  ],
                ),
                Gap(12),
                HyperGroup(
                  inSliver: false,
                  children: [
                    Container(
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      child: Text("这是MixMusic，一个基于插件的音乐播放器"),
                    )
                  ],
                ),
                Gap(12),
                HyperGroup(
                  inSliver: false,
                  children: [
                    Gap(12),
                    Container(
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text("欢迎加入频道与我联系！"),
                    ),
                    Container(
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text("企鹅频道:"),
                    ),
                    Container(
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text("pd49827934"),
                    ),
                    Gap(12),
                  ],
                ),
                Gap(12),
                HyperGroup(
                  inSliver: false,
                  children: [
                    Container(
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      child: Text("如果觉着软件还不错，也可以请作者喝杯咖啡~😊"),
                    )
                  ],
                ),
              ],
            ),
            ListView(
              children: [
                HyperGroup(
                  inSliver: false,
                  title: Text("微信"),
                  children: [
                    Container(
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      child: Image.asset("assets/weixin.jpg", width: 250),
                    )
                  ],
                ),
                HyperGroup(
                  inSliver: false,
                  title: Text("支付宝"),
                  children: [
                    Container(
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      child: Image.asset("assets/zfb.jpg", width: 250),
                    )
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
