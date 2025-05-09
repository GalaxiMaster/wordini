import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

Future<Map> readData({String path = 'words'}) async{
  Map jsonData= {};
  debugPrint("${path}id");
  final dir = await getApplicationDocumentsDirectory();
  String filepath = '${dir.path}/$path.json';
  debugPrint(filepath);
  var file = File(filepath);
  var exists = await file.exists();
  debugPrint(exists.toString());
  // Read the file as a string
  if (await file.exists()) {
    String contents = await file.readAsString();
    if (contents.isNotEmpty){
      jsonData = jsonDecode(contents);
    }    
    debugPrint("${jsonData}json data");
  }
  return jsonData;
}

Future<void> writeData(Map newData, {String path = 'words', bool append = true}) async {
  try {
    final dir = await getApplicationDocumentsDirectory();

    // Path handling: split the provided path into directory and file name components
    List<String> pathComponents = path.split('/');
    String directoryPath = '${dir.path}/${pathComponents.sublist(0, pathComponents.length - 1).join('/')}';
    String filePath = '${dir.path}/$path.json';

    // If appending is enabled, merge existing data with new data
    if (append) {
      Map existingData = await readData(path: path);
      newData = Map<String, dynamic>.from(newData)..addAll(Map<String, dynamic>.from(existingData));
    }

    // Ensure the directory exists, create it if not
    Directory routineDir = Directory(directoryPath);
    if (!routineDir.existsSync()) {
      await routineDir.create(recursive: true);  // Create directory recursively if necessary
    }

    // Convert map data to JSON string
    String jsonString = jsonEncode(newData);

    // Write the JSON data to the file
    File file = File(filePath);
    await file.writeAsString(jsonString);

    debugPrint('Data has been written to the file: $filePath');

  } catch (e) {
    // Catch and report any errors
    debugPrint('Error writing data: $e');
  }
  
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