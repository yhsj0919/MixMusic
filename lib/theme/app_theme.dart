import 'dart:ui';

import 'package:flutter/material.dart';

final platformBrightness = PlatformDispatcher.instance.platformBrightness;

final lightTheme = ThemeData(
  colorScheme: const ColorScheme.light(
    // 主色调
    primary: Colors.blue,
    // 文字颜色
    onSurface: Colors.black,
    onSecondary: Color(0xff9093a8),
    onTertiary: Color(0xff999999),
    // 表面颜色
    surface: Color(0xFFF7F7F7),
    surfaceContainer: Colors.white,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: const Color(0xFFF7F7F7),
    surfaceTintColor: Colors.transparent,
    centerTitle: true,
  ),
  listTileTheme: ListTileThemeData(
      subtitleTextStyle: TextStyle(
        fontSize: 14,
        color: const Color(0xff999999),
      ),
      contentPadding: const EdgeInsets.only(left: 16, right: 14)),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(
      fontSize: 18,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
    ),
    labelMedium: TextStyle(fontSize: 14, color: Color(0xff9093a8)),
    titleLarge: TextStyle(
      fontSize: 20,
    ),
  ),
  useMaterial3: true,
);

final darkTheme = ThemeData(
  colorScheme: const ColorScheme.dark(
    // 主色调
    primary: Colors.blue,
    // 文字颜色
    onSurface: Colors.white,
    onSecondary: Color(0xff9093a8),
    onTertiary: Color(0xff999999),
    // 表面颜色
    surface: Colors.black,
    surfaceContainer: Color(0xff242424),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.black,
    surfaceTintColor: Colors.transparent,
    centerTitle: true,
  ),
  listTileTheme: ListTileThemeData(
    subtitleTextStyle: TextStyle(
      fontSize: 14,
      color: const Color(0xff999999),
    ),
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(
      fontSize: 18,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
    ),
    labelMedium: TextStyle(fontSize: 14, color: Color(0xff9093a8)),
    titleLarge: TextStyle(
      fontSize: 20,
    ),
  ),
  useMaterial3: true,
);
