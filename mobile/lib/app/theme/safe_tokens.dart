import 'package:flutter/material.dart';

abstract final class SafeSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

abstract final class SafeRadii {
  static const sm = BorderRadius.all(Radius.circular(12));
  static const md = BorderRadius.all(Radius.circular(16));
  static const lg = BorderRadius.all(Radius.circular(24));
}

abstract final class SafeElevation {
  static const card = 1.0;
  static const raised = 2.0;
}

abstract final class SafeContentWidth {
  static const readable = 720.0;
}
