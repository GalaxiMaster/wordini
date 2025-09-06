import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wordini/Providers/goal_providers.dart';
import 'package:wordini/Providers/otherproviders.dart';
import 'package:wordini/widgets.dart';
import 'package:file_picker/file_picker.dart';
import 'package:wordini/word_functions.dart';

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

Future<void> deleteKey(String word, {String path = 'words'}) async {
  final box = await Hive.openBox(path);
  await box.delete(word);
  debugPrint('Deleted word "$word" from box "$path"');
}

Future<void> writeKey(String key, dynamic data, {String path = 'words',}) async {
  final box = await Hive.openBox(path);
  box.put(key, data);
  debugPrint('Writing Key "$key" from box "$path"');
}

Future<dynamic> readKey(String key, {String path = 'words', dynamic defaultValue}) async {
  final box = await Hive.openBox(path);
  return box.get(key, defaultValue: defaultValue);
}

Future<List?> resetData(BuildContext? context, WidgetRef ref, {String? path}) async {
  List? choices;
  if (path != null){
    choices = [path];
  } else {
    choices = await getChoices(context);
  }
  if (choices == null || choices.isEmpty) return null;
  if (context != null && context.mounted) {
    // Add confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Reset'),
        content: Text(
          'Are you sure you want to reset the following data?\n\n${choices!.join(', ')}\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true) return null;
  }
  final Map refKeys = {
    'words': wordDataFutureProvider,
    'inputs': futureInputDataProvider,
    'settings': futureSettingsDataProvider,
    'archivedWords': archivedWordsDataProvider,
  };
  for (String choice in choices){
    final box = await Hive.openBox(choice);
    await box.clear();
    if (refKeys.containsKey(choice)){
      try {
        final provider = refKeys[choice];
        ref.invalidate(provider);
      } catch (e){
        debugPrint(e.toString());
      }
      
    }
  }
  return choices;
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

Future<void> exportJson(BuildContext context) async {
  LoadingOverlay loadingOverlay = LoadingOverlay();
  try {

    List? exportChoices = await getChoices(context);
    if (context.mounted) loadingOverlay.showLoadingOverlay(context);
    Map data = {};
    if (exportChoices == null) return;
    for (String choice in exportChoices){
      final box = await Hive.openBox(choice);
      final boxData = Map<String, dynamic>.from(box.toMap());
      data[choice] = boxData;
    }


    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/export.json';

    final file = File(path);

    // Write the JSON to a file
    final jsonString = const JsonEncoder.withIndent('  ').convert(data);
    await file.writeAsString(jsonString);

    // Share the file
    if (await file.exists()) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path)],
          text: 'Exported data from Wordini',
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
Future<List?> getChoices(context) async{
  final List? choices = await showDialog(
    context: context,
    builder: (context) {
      Map options = {
        'words': true,
        'inputs': true,
        // 'settings': true
      };
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Data to export:'),
            content: IntrinsicHeight(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (String option in options.keys)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(capitalise(option)),
                        Switch.adaptive(
                          value: options[option],
                          onChanged: (value) {
                            debugPrint('balls $value ${options[option]}');
                            setState(() {
                              options[option] = value;
                            });
                          },
                        ),
                      ],
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(options.entries.where((entry) => entry.value).map((entry)=> entry.key).toList()),
                child: const Text('OK!'),
              ),
            ],
          );
        },
      );
    },
  );
  return choices;
}
Future<void> importData(BuildContext context) async {
  try {
    final result = await _pickJsonFile();
    if (result == null) return;

    final content = await _readFileContent(result);
    if (content == null) return;

    final jsonData = _parseJson(content);
    if (jsonData == null) {
      if (context.mounted) _showErrorDialog(context, "Invalid JSON file.");
      return;
    }
    for (String key in jsonData.keys){
      await writeData(jsonData[key], append: true, path: key);
    }

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

Future<void> getUserPermissions() async {
  Map<String, dynamic> permissions;
  const defaultPermissions = {'canQuiz': false};

  try {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('User-Permissions')
          .doc(user.uid)
          .get();
      
      permissions = doc.exists ? doc.data() as Map<String, dynamic> : defaultPermissions;
    } else {
      permissions = defaultPermissions;
    }
  } catch (e) {
    debugPrint('Error fetching permissions: $e');
    permissions = defaultPermissions;
  }

  final permissionsBox = Hive.box('permissions');

  permissionsBox.put('canQuiz', permissions['canQuiz'] ?? false);
}

Future<void> createDefaultPermissions(UserCredential userCredential) async {
  final user = userCredential.user;
  if (user == null) return;

  final defaultPermissions = {
    'canQuiz': false,
  };

  try {
    await FirebaseFirestore.instance
        .collection('User-Permissions')
        .doc(user.uid)
        .set(defaultPermissions);
  } catch (e) {
    debugPrint("Error creating permissions document: $e");
  }
}