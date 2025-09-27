import 'package:fluent_ui/fluent_ui.dart';
import 'package:mix_music/common/entity/mix_album.dart';
import 'package:mix_music/common/entity/mix_artist.dart';
import 'package:mix_music/common/entity/mix_song.dart';
import 'package:mix_music/widgets/app_image.dart';
import 'package:mix_music/widgets/ext.dart';

class HomeArtistItem extends StatefulWidget {
  const HomeArtistItem({super.key, required this.item, this.onTap});

  final MixArtist item;
  final GestureTapCallback? onTap;

  @override
  State<HomeArtistItem> createState() => _HomeArtistItemState();
}

class _HomeArtistItemState extends State<HomeArtistItem> {
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
        child: Container(
          padding: EdgeInsets.all(4),
          width: 160,
          height: 182,
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
                // alignment: Alignment.centerLeft,
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  widget.item.title ?? "",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FluentTheme.of(context).typography.body?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
