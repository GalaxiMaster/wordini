import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vocab_app/widgets.dart';
import 'package:file_picker/file_picker.dart';

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

Future<void> exportJson(BuildContext context, {String boxName = 'words'}) async {
  LoadingOverlay loadingOverlay = LoadingOverlay();
  try {
    loadingOverlay.showLoadingOverlay(context);
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
          text: 'Exported data from vocab app',
        ),
      );

    } else {
      debugPrint('Error: Exported JSON file does not exist');
    }
  } catch (e) {
    debugPrint('Error exporting JSON: $e');
  }
  loadingOverlay.removeLoadingOverlay();
}

Future<void> importData(BuildContext context) async {
  try {
    final result = await _pickJsonFile();
    if (result == null) return;

    final content = await _readFileContent(result);
    if (content == null) return;

    final jsonData = _parseJson(content);
    if (jsonData == null) {
      _showErrorDialog(context, "Invalid JSON file.");
      return;
    }

    await writeData(jsonData, append: true);

    if (!context.mounted) return; // resolves build_context_synchronously warning
    _showSuccessDialog(context);

    debugPrint("Parsed JSON data: $jsonData");
  } catch (e) {
    debugPrint("Error during import: $e");
    if (context.mounted) {
      _showErrorDialog(context, "Failed to import data. $e");
    }
  }
}

Future<File?> _pickJsonFile() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['json'],
  );
  if (result == null || result.files.isEmpty) return null;

  final path = result.files.single.path;
  return path != null ? File(path) : null;
}

Future<String?> _readFileContent(File file) async {
  try {
    return await file.readAsString();
  } catch (e) {
    debugPrint("Failed to read file: $e");
    return null;
  }
}

Map<String, dynamic>? _parseJson(String content) {
  try {
    return jsonDecode(content) as Map<String, dynamic>;
  } catch (e) {
    debugPrint("JSON decode error: $e");
    return null;
  }
}

void _showSuccessDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Data Imported'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

void _showErrorDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Error'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
