// Utility function for deep copying a Map
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