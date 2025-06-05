import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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

Future<void> addInputEntry(String word, String partOfSpeech, Map entry) async{
  final Box box = await Hive.openBox('inputs');
  Map data = box.get(word, defaultValue: {});
  data[partOfSpeech] ??= [];
  data[partOfSpeech].insert(0, entry);
  box.put(word, data);
}

Future<void> exportJson({String boxName = 'words'}) async {
  try {
    final box = await Hive.openBox(boxName);
    final data = Map<String, dynamic>.from(box.toMap());

    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/$boxName-export.json';

    final file = File(path);

    // Write the JSON to a file
    final jsonString = const JsonEncoder.withIndent('  ').convert(data);
    await file.writeAsString(jsonString);

    // Share the file
    if (await file.exists()) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path)],
          text: '📚 Exported data from "$boxName"',
        ),
      );

    } else {
      debugPrint('Error: Exported JSON file does not exist');
    }
  } catch (e) {
    debugPrint('Error exporting JSON: $e');
  }
}
