import 'package:flutter/material.dart';
import 'package:flutter_lyric/flutter_lyric.dart';

LyricStyle buildMixLyricStyle({
  required double defaultSize,
  required double defaultExtSize,
  required double otherMainSize,
  required bool highlight,
  required Color playingMainTextColor,
  required Color playingOtherMainTextColor,
  required EdgeInsets contentPadding,
  Color? selectedColor = Colors.black,
}) {
  final base = LyricStyles.default1;
  return base.copyWith(
    selectedColor: selectedColor,
    textStyle: TextStyle(color: playingOtherMainTextColor, fontSize: otherMainSize, fontWeight: FontWeight.bold, height: 1.2),
    activeStyle: TextStyle(color: playingMainTextColor, fontSize: defaultSize, fontWeight: FontWeight.bold, height: 1.2),
    translationStyle: TextStyle(color: playingMainTextColor.withOpacity(0.6), fontSize: defaultExtSize, height: 1.2),
    contentPadding: contentPadding,
    lineGap: 25,
    translationLineGap: 10,
    textAlign: TextAlign.center,
    contentAlignment: CrossAxisAlignment.center,
    activeHighlightColor: highlight ? base.activeHighlightColor : null,
    activeHighlightGradient: highlight ? base.activeHighlightGradient : null,
  );
}
