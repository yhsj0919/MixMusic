import 'package:cached_network_image/cached_network_image.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';

class AppImage extends StatefulWidget {
  const AppImage({
    Key? key,
    required this.url,
    this.width = 50,
    this.height = 50,
    this.fit = BoxFit.cover,
    this.radius,
    this.animationDuration,
  }) : super(key: key);
  final String url;
  final double? width;
  final double? height;
  final double? radius;
  final int? animationDuration;
  final BoxFit fit;

  @override
  _AppImageState createState() => _AppImageState();
}

class _AppImageState extends State<AppImage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(vsync: this, duration: Duration(milliseconds: widget.animationDuration ?? 500), lowerBound: 0.0, upperBound: 1.0);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(widget.radius ?? 8)),
      child: widget.url.isNotEmpty
          ? RepaintBoundary(
              child: ExtendedImage(
                image: CachedNetworkImageProvider(
                  widget.url,
                  headers: const {
                    'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/117.0.0.0 Safari/537.36 Edg/117.0.2045.35'
                  },
                ),
                fit: widget.fit,
                width: widget.width,
                height: widget.height,
                border: Border.all(color: Colors.black12, width: 1.0),
                borderRadius: BorderRadius.all(Radius.circular(widget.radius ?? 8)),
                loadStateChanged: (ExtendedImageState state) {
                  switch (state.extendedImageLoadState) {
                    case LoadState.loading:
                      _controller.reset();
                      return Container(width: widget.width, height: widget.height, color: Colors.black12, alignment: Alignment.center);
                    case LoadState.completed:
                      _controller.forward();
                      return FadeTransition(
                        opacity: _controller,
                        child: ExtendedRawImage(
                          fit: widget.fit,
                          image: state.extendedImageInfo?.image,
                          width: widget.width,
                          height: widget.height,
                        ),
                      );
                    case LoadState.failed:
                      _controller.reset();
                      state.imageProvider.evict();
                      return GestureDetector(
                        child: Container(color: Colors.black12),
                        onTap: () {
                          state.reLoadImage();
                        },
                      );
                  }
                },
              ),
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
    _controller.dispose();
    super.dispose();
  }
}
