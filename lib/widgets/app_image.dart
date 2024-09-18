import 'package:cached_network_image/cached_network_image.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';

class AppImage extends StatefulWidget {
  const AppImage({Key? key, required this.url, this.width = 50, this.height = 50, this.fit = BoxFit.cover, this.radius, this.animationDuration, this.border}) : super(key: key);
  final String url;
  final double? width;
  final double? height;
  final double? radius;
  final int? animationDuration;
  final BoxFit fit;
  final BoxBorder? border;

  @override
  _AppImageState createState() => _AppImageState();
}

class _AppImageState extends State<AppImage> with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(widget.radius ?? 8)),
      child: widget.url.isNotEmpty
          ? ExtendedImage(
              image: CachedNetworkImageProvider(
                widget.url,
                headers: const {
                  'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/117.0.0.0 Safari/537.36 Edg/117.0.2045.35'
                },
              ),
              fit: widget.fit,
              width: widget.width,
              height: widget.height,
              border: widget.border,
              borderRadius: BorderRadius.all(Radius.circular(widget.radius ?? 8)),
              loadStateChanged: (ExtendedImageState state) {
                switch (state.extendedImageLoadState) {
                  case LoadState.loading:
                    return Container(width: widget.width, height: widget.height, color: Colors.black12, alignment: Alignment.center);
                  case LoadState.completed:
                    return ExtendedRawImage(
                      fit: widget.fit,
                      image: state.extendedImageInfo?.image,
                      width: widget.width,
                      height: widget.height,
                    );
                  case LoadState.failed:
                    state.imageProvider.evict();
                    return GestureDetector(
                      child: Container(color: Colors.black12),
                      onTap: () {
                        state.reLoadImage();
                      },
                    );
                }
              },
            )
          : Container(
              width: widget.width,
              height: widget.height,
              color: Colors.black12,
            ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
