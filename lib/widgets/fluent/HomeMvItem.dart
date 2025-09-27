import 'package:fluent_ui/fluent_ui.dart';
import 'package:mix_music/common/entity/mix_album.dart';
import 'package:mix_music/common/entity/mix_mv.dart';
import 'package:mix_music/widgets/app_image.dart';
import 'package:mix_music/widgets/ext.dart';

class HomeMvItem extends StatefulWidget {
  const HomeMvItem({super.key, required this.item, this.onTap});

  final MixMv item;
  final GestureTapCallback? onTap;

  @override
  State<HomeMvItem> createState() => _HomeMvItemState();
}

class _HomeMvItemState extends State<HomeMvItem> {
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
          width: 270,
          height: 200,
          decoration: BoxDecoration(color: onUp ? Colors.black.withAlpha((255 * 0.1).toInt()) : null, borderRadius: BorderRadius.circular(8)),
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Hero(
                  tag: "${widget.item.package}${widget.item.id}${widget.item.pic}",
                  child: AppImage(url: widget.item.pic ?? "", width: 270, height: 160, radius: 6),
                ),
              ).expanded(),
              Container(
                height: 22,
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  widget.item.title ?? "",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FluentTheme.of(context).typography.body?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                height: 22,
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  widget.item.artist?.map((e) => e.title ?? "").join(",") ?? "",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FluentTheme.of(context).typography.caption,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
