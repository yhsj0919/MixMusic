import 'package:fluent_ui/fluent_ui.dart';
import 'package:mix_music/common/entity/mix_play_list.dart';
import 'package:mix_music/widgets/app_image.dart';
import 'package:mix_music/widgets/ext.dart';

class HomePlayListItem extends StatefulWidget {
  const HomePlayListItem({super.key, required this.item, this.onTap});

  final MixPlaylist item;
  final GestureTapCallback? onTap;

  @override
  State<HomePlayListItem> createState() => _HomePlayListItemState();
}

class _HomePlayListItemState extends State<HomePlayListItem> {
  bool onUp = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (widget.onTap != null) {
          setState(() {
            onUp = true;
          });
        }
      },
      onExit: (_) {
        if (widget.onTap != null) {
          setState(() {
            onUp = false;
          });
        }
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          padding: EdgeInsets.all(4),
          duration: Duration(milliseconds: 200),
          width: 160,
          height: 200,
          decoration: BoxDecoration(
            color: onUp ? Colors.black.withAlpha((255 * 0.1).toInt()) : null,
            // border: Border.all(
            //   color: onUp ? Colors.green : Colors.blue, // 根据状态改变边框颜色
            //   width: 2,
            // ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: 160/158,
                child: Hero(
                  tag: "${widget.item.package}${widget.item.id}${widget.item.pic}",
                  child: AppImage(url: widget.item.pic ?? "", width: 160, height: 160, radius: 6),
                ),
              ).expanded(),
              Container(
                height: 42,
                alignment: Alignment.topLeft,
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(widget.item.title ?? "", maxLines: 2, overflow: TextOverflow.ellipsis, style: FluentTheme.of(context).typography.body),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
