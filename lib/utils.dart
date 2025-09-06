// Utility function for deep copying a Map
import 'package:flutter/material.dart';

Map deepCopy(Map original) {
  return Map.from(original.map((key, value) {
    if (value is Map) {
      return MapEntry(key, deepCopy(Map.from(value)));
    } else if (value is List) {
      return MapEntry(key, value.map((item) => item is Map ? deepCopy(Map<String, dynamic>.from(item)) : item).toList());
    } else {
      return MapEntry(key, value);
    }
  }));
}

Color lighten(Color color, [double amount = .1]) {
  assert(amount >= 0 && amount <= 1);
  final hsl = HSLColor.fromColor(color);
  final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
  return hslLight.toColor();
}