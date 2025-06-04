import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
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
  debugPrint('✅ Data written to Hive box: $path');
}
/// Deletes a word from the Hive box.
Future<void> deleteWord(String word, {String path = 'words'}) async {
  final box = await Hive.openBox('words');
  await box.delete(word);
  debugPrint('🗑️ Deleted word "$word" from box "$path"');
}
/// Reads a single word's data from the given Hive box.
Future<dynamic> readOneWord(String word, {String path = 'words'}) async {
  final box = await Hive.openBox(path);
  return box.get(word);
}

Future<void> resetData(bool output, bool current, bool records) async {
  if (output){
    try {
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/words.json';
      final file = File(path);
      await file.writeAsString('');
      debugPrint('json reset at: $path');
    } catch (e) {
      debugPrint('Error saving json file: $e');
    }
  }
}

void deleteFile(String fileName) async{
  final dir = await getApplicationDocumentsDirectory();
  final path = '${dir.path}/$fileName.json';
  final file = File(path);
  if (await file.exists()) {
    await file.delete();   
  }
}