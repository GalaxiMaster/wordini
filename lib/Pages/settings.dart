import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:wordini/Pages/Account/account.dart';
import 'package:wordini/Pages/Account/sign_in.dart';
import 'package:wordini/Pages/word_details.dart';
import 'package:wordini/file_handling.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:wordini/word_functions.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: FutureBuilder(
        future: readData(path: 'settings'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading data'));
          } else if (snapshot.hasData) {
            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                settingsHeader('Account'),
                const SizedBox(height: 8),
                _buildSettingsTile(
                  icon: Icons.person,
                  label: 'Account',
                  function: () async{ // When clicked, toggle a button somewhere that makes sure you can't click it twice, either by just having a backend variable or a loading widget on screen while its
                    User? user = FirebaseAuth.instance.currentUser;
                    if (user != null){
                      await reAuthUser(user, context);
                      user = FirebaseAuth.instance.currentUser;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AccountPage(accountDetails: user!),
                        ),
                      );  
                    }else{
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SignInPage(),
                        ),
                      );  
                    }
                  },
                ),
                settingsHeader('Functions'),
                const SizedBox(height: 8),
                _buildSettingsTile(
                  icon: Icons.upload_rounded,
                  label: 'Export Data',
                  function: () async {
                    await exportJson(context);
                  },
                ),
                _buildSettingsTile(
                  icon: Icons.download_rounded,
                  label: 'Import Data',
                  function: () async {
                    await importData(context);
                  },
                ),
                _buildSettingsTile(
                  icon: Icons.restart_alt,
                  label: 'Reset Data',
                  function: () async {
                    await resetData(context);
                  },
                ),
                _buildSettingsTile(
                  icon: Icons.download_rounded,
                  label: 'Import CSV',
                  function: () async {
                    await processCsvRows(context);
                  },
                ),
              ],
            );
          } else {
            return const Center(child: Text('No data available'));
          }
        },
      ),
    );
  }

  Widget settingsHeader(String header) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 16, bottom: 8),
      child: Text(
        header.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String label,
    required VoidCallback? function,
    Widget? rightside,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        onTap: function,
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        trailing: rightside ?? const Icon(Icons.arrow_forward_ios_rounded, size: 16),
      ),
    );
  }
}

Future<void> processCsvRows(context) async {
  final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv']);

  if (result != null) {
    final file = File(result.files.single.path!);
    final content = await file.readAsString();
    final rows = const CsvToListConverter().convert(content);
    
    final allTags = await gatherTags();
    for (var row in rows) {
      String word = row[0].toString();
      // final String definition = row[1].toString();
      final Map wordDetails = await getWordDetails(word.toLowerCase());
      word = wordDetails['word'];
      if (wordDetails.isNotEmpty) {
        debugPrint('Word exists: $word');
        writeKey(word, wordDetails);
      } else {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => WordDetails(
            word: {
              "word": word,
              "dateAdded": DateTime.now().toString(),
              "entries": {
            
              }
            }, 
            editModeState: true,
            allTags: allTags,
            addWordMode: true,
          ))
        );
      }
    }
  } else {
    debugPrint('No file selected.');
  }
}
