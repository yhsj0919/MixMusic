import 'package:flutter/material.dart';
import 'package:mix_music/api/api_factory.dart';
import 'package:mix_music/entity/mix_song.dart';
import 'package:mix_music/widgets/app_image.dart';

class MixSiteItem extends StatelessWidget {
  const MixSiteItem({super.key, required this.mixSong, this.size = 20});

  final MixSong? mixSong;
  final double size;

  @override
  Widget build(BuildContext context) {
    var site = ApiFactory.getPlugin(mixSong?.package);
    var match = ApiFactory.getPlugin(mixSong?.matchSong?.package);

    return Stack(
      alignment: Alignment.center,
      children: [
        site?.icon != null
            ? ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(30)),
                child: Container(
                  color: Colors.white,
                  child: AppImage(
                    url: site?.icon ?? "",
                    radius: 30,
                    width: size,
                    height: size,
                  ),
                ))
            : Container(
                width: size,
                height: size,
              ),
        match == null
            ? Container(height: size, width: size)
            : Container(
                margin: EdgeInsets.only(left: size + size / 2),
                child: ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                    child: Container(
                      color: Colors.white,
                      child: AppImage(
                        url: match.icon ?? "",
                        radius: 30,
                        width: size,
                        height: size,
                      ),
                    )),
              ),
      ],
    );
  }
}
