import 'package:flutter/material.dart';
import 'package:mix_music/api/api_factory.dart';
import 'package:mix_music/entity/mix_song.dart';
import 'package:mix_music/widgets/app_image.dart';

class MixQualityIcon extends StatelessWidget {
  const MixQualityIcon({super.key, this.quality, this.size = 20});

  final int? quality;
  final double size;

  @override
  Widget build(BuildContext context) {
    var myText = getByQuality(quality ?? 128);

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
            // width: size,
            height: size,
            padding: EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.light ? Colors.black : Colors.white, // 边框颜色
                width: 2.0, // 边框宽度
              ),
              borderRadius: BorderRadius.circular(2.0), // 边框圆角
            ),
            child: Badge(
              backgroundColor: Colors.red.withValues(alpha: 0.7),
              textColor: Theme.of(context).brightness == Brightness.light ? Colors.black : Colors.white,
              // 边框颜色
              offset: Offset(10, -10),
              label: Text("${quality ?? ""}"),
              isLabelVisible: myText == null && quality != null,
              child: Text(
                myText ?? "HD",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
              ),
            )),
      ],
    );
  }

  String? getByQuality(int quality) {
    switch (quality) {
      case 128:
        return "PQ";
      case 320:
        return "HQ";
      case 1000:
        return "SQ";
      case 2000:
        return "HR";
      case 3000:
        return "MQ";
      default:
        return null;
    }
  }
}
