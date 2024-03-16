import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_lyric/lyric_ui/lyric_ui.dart';

///Sample Netease style
///should be extends LyricUI implementation your own UI.
///this property only for change UI,if not demand just only overwrite methods.
class UIMix extends LyricUI {
  double defaultSize;
  double defaultExtSize;
  double otherMainSize;
  double bias;
  double lineGap;
  double inlineGap;
  LyricAlign lyricAlign;
  LyricBaseLine lyricBaseLine;
  bool highlight;
  HighlightDirection highlightDirection;
  Color playingMainTextColor;
  Color playingOtherMainTextColor;
  Color highLightColor;

  UIMix({
    this.defaultSize = 18,
    this.defaultExtSize = 14,
    this.otherMainSize = 16,
    this.bias = 0.5,
    this.lineGap = 25,
    this.inlineGap = 25,
    this.lyricAlign = LyricAlign.CENTER,
    this.lyricBaseLine = LyricBaseLine.CENTER,
    this.highlight = true,
    this.highlightDirection = HighlightDirection.LTR,
    this.highLightColor = Colors.black,
    this.playingMainTextColor = Colors.black,
    this.playingOtherMainTextColor = Colors.black26,
  });

  UIMix.clone(UIMix uiMix)
      : this(
          defaultSize: uiMix.defaultSize,
          defaultExtSize: uiMix.defaultExtSize,
          otherMainSize: uiMix.otherMainSize,
          bias: uiMix.bias,
          lineGap: uiMix.lineGap,
          inlineGap: uiMix.inlineGap,
          lyricAlign: uiMix.lyricAlign,
          lyricBaseLine: uiMix.lyricBaseLine,
          highlight: uiMix.highlight,
          highlightDirection: uiMix.highlightDirection,
        );

  @override
  TextStyle getPlayingExtTextStyle() => TextStyle(color: playingMainTextColor.withOpacity(0.5), fontSize: defaultExtSize);

  @override
  TextStyle getOtherExtTextStyle() => TextStyle(
        color: Colors.grey[300],
        fontSize: defaultExtSize,
      );

  @override
  getLyricHightlightColor() => highLightColor;

  @override
  TextStyle getOtherMainTextStyle() => TextStyle(color: playingOtherMainTextColor, fontSize: otherMainSize, fontWeight: FontWeight.bold);

  @override
  TextStyle getPlayingMainTextStyle() => TextStyle(color: playingMainTextColor, fontSize: defaultSize, fontWeight: FontWeight.bold);

  @override
  double getInlineSpace() => inlineGap;

  @override
  double getLineSpace() => lineGap;

  @override
  double getPlayingLineBias() => bias;

  @override
  LyricAlign getLyricHorizontalAlign() => lyricAlign;

  @override
  LyricBaseLine getBiasBaseLine() => lyricBaseLine;

  @override
  bool enableHighlight() => highlight;

  @override
  HighlightDirection getHighlightDirection() => highlightDirection;
}
