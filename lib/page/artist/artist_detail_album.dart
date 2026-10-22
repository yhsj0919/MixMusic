import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lemon_ui/lemon_ui.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../common/plugin/collection_controller.dart';

class ArtistDetailAlbum extends StatefulWidget {
  const ArtistDetailAlbum({super.key, required this.collection});
  final CollectionController collection;

  @override
  State<ArtistDetailAlbum> createState() => _ArtistDetailAlbumState();
}

class _ArtistDetailAlbumState extends State<ArtistDetailAlbum> {
  @override
  void initState() {
    super.initState();
    if (widget.collection.albumPage == 0) widget.collection.loadMoreAlbums();
  }

  @override
  Widget build(BuildContext context) {
    final collection = widget.collection;
    return HyperScaffold(
      appBar: HyperAppBar(
        title: HyperText('${collection.resource.title} · 专辑'),
        automaticallyImplyLeading: false,
        leading: HyperDeviceDetector.of(context) == HyperDeviceType.desktop
            ? null
            : HyperIconButton.ghost(
                tooltip: '返回',
                icon: const HyperIcon(Icons.arrow_back_rounded),
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/'),
              ),
      ),
      body: NotificationListener<ScrollUpdateNotification>(
        onNotification: (event) {
          if (event.depth == 0 &&
              event.metrics.extentAfter < 240 &&
              collection.albumsError.value.isEmpty) {
            collection.loadMoreAlbums();
          }
          return false;
        },
        child: Obx(() {
          final albums = collection.albums.value;
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: albums.length + 1,
            itemBuilder: (context, index) {
              if (index < albums.length) {
                final album = albums[index];
                return HyperListTile(
                  leading: const HyperIcon(Icons.album_outlined),
                  title: HyperText(album.title),
                  subtitle: HyperText(album.subtitle ?? ''),
                  onTap: () => context.push('/album', extra: album),
                );
              }
              return Obx(
                () => Column(
                  children: [
                    if (collection.albumsLoading.value)
                      const HyperText('正在加载…')
                    else if (collection.albumsError.value.isNotEmpty) ...[
                      HyperText('加载失败：${collection.albumsError.value}'),
                      HyperButton.text(
                        onPressed: collection.loadMoreAlbums,
                        label: const HyperText('重试'),
                      ),
                    ] else if (collection.albumsHasMore.value)
                      HyperButton.text(
                        onPressed: collection.loadMoreAlbums,
                        label: const HyperText('加载更多'),
                      )
                    else
                      HyperText(albums.isEmpty ? '暂无专辑' : '已加载全部专辑'),
                  ],
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
