import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:mix_music/widgets/fluent/fluent_group.dart';
import 'package:mix_music/widgets/hyper/hyper_group.dart';

class DesktopAboutPage extends StatefulWidget {
  const DesktopAboutPage({super.key});

  @override
  State<DesktopAboutPage> createState() => _DesktopAboutPageState();
}

class _DesktopAboutPageState extends State<DesktopAboutPage>
    with TickerProviderStateMixin {
  var items = ["关于", "赞赏"];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage.scrollable(
      header: PageHeader(
        title: Text('MixMusic'),
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
      children: [
        Container(
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Text("👏你好，很高兴认识你！"),
        ),
        Container(
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Text("这是MixMusic，一个基于插件的音乐播放器"),
        ),
        Gap(12),
        Container(
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Text("欢迎加入频道与我联系！"),
        ),
        Gap(12),
        Container(
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Text("企鹅频道: pd49827934"),
        ),
        Gap(12),
        Container(
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Text("如果觉着软件还不错，也可以请作者喝杯咖啡~😊"),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: FluentGroup(
                inSliver: false,
                title: Text("微信"),
                children: [
                  Container(
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    child: Image.asset("assets/weixin.jpg", width: 250),
                  ),
                ],
              ),
            ),
            Flexible(
              child: FluentGroup(
                inSliver: false,
                title: Text("支付宝"),
                children: [
                  Container(
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    child: Image.asset("assets/zfb.jpg", width: 250),
                  ),
                ],
              ),
            ),
            Expanded(child: Container()),
          ],
        ),
        // Row(
        //   children: [
        //     HyperGroup(
        //       inSliver: false,
        //       title: Text("微信"),
        //       children: [
        //         Container(
        //           alignment: Alignment.centerLeft,
        //           padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        //           child: Image.asset("assets/weixin.jpg", width: 250),
        //         ),
        //       ],
        //     ),
        //     HyperGroup(
        //       inSliver: false,
        //       title: Text("支付宝"),
        //       children: [
        //         Container(
        //           alignment: Alignment.centerLeft,
        //           padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        //           child: Image.asset("assets/zfb.jpg", width: 250),
        //         ),
        //       ],
        //     ),
        //   ],
        // ),
      ],
    );
  }
}
