import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

Future<Map<String, dynamic>> readData({String path = 'words'}) async {
  final box = await Hive.openBox(path);
  return Map<String, dynamic>.from(box.toMap());
}

Future<void> writeData(
  Map<String, dynamic> newData, {
  String path = 'words',
  bool append = true,
}) async {
  final box = await Hive.openBox(path);

  if (!append) {
    await box.clear();
  }

  await box.putAll(newData);
  debugPrint('Data written to Hive box: $path');
}

Future<void> deleteWord(String word, {String path = 'words'}) async {
  final box = await Hive.openBox('words');
  await box.delete(word);
  debugPrint('Deleted word "$word" from box "$path"');
}

Future<void> writeWord(String key, Map data, {String path = 'words',}) async {
  final box = await Hive.openBox(path);
  box.put(key, data);
}

Future<dynamic> readKey(String key, {String path = 'words'}) async {
  final box = await Hive.openBox(path);
  return box.get(key);
}

Future<void> resetData({String path = 'words',}) async {
  final box = await Hive.openBox(path);

  await box.clear();
}

Future<Set> gatherTags() async{
  final box = await readData();

  Set allTags = box.values
    .expand((w) => w['tags'] ?? [])
    .toSet(); // Collect all unique tags from all words
  return allTags;
}

Future<void> addInputEntry(String word, Map entry) async{
  final Box box = await Hive.openBox('inputs');
  List data = box.get(word, defaultValue: []);
  data.insert(0, entry);
  box.put(word, data);
}