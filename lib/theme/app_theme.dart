import 'dart:ui';

import 'package:flutter/material.dart';

final platformBrightness = PlatformDispatcher.instance.platformBrightness;


final lightTheme = ThemeData.light(
  useMaterial3: true,
);

final darkTheme = ThemeData.dark(
  useMaterial3: true,
);
