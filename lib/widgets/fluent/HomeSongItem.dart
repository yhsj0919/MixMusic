import 'package:fluent_ui/fluent_ui.dart';
import 'package:mix_music/common/entity/mix_album.dart';
import 'package:mix_music/common/entity/mix_song.dart';
import 'package:mix_music/widgets/app_image.dart';
import 'package:mix_music/widgets/ext.dart';

class HomeSongItem extends StatefulWidget {
  const HomeSongItem({super.key, required this.item, this.onTap});

  final MixSong item;
  final GestureTapCallback? onTap;

  @override
  State<HomeSongItem> createState() => _HomeSongItemState();
}

class _HomeSongItemState extends State<HomeSongItem> {
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
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.all(4),
          width: 160,
          height: 204,
          decoration: BoxDecoration(color: onUp ? Colors.black.withAlpha((255 * 0.1).toInt()) : null, borderRadius: BorderRadius.circular(8)),

          child: Column(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Hero(
                  tag: "${widget.item.package}${widget.item.id}${widget.item.pic}",
                  child: AppImage(url: widget.item.pic ?? "", width: 160, height: 160, radius: 160),
                ),
              ).expanded(),
              Container(
                height: 22,
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.item.title ?? "",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: FluentTheme.of(context).typography.body?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    widget.item.vip == 1
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
