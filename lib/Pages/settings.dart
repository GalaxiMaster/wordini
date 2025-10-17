import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wordini/Pages/Account/account.dart';
import 'package:wordini/Pages/Account/sign_in.dart';
import 'package:wordini/Pages/archived_words.dart';
import 'package:wordini/Pages/word_details.dart';
import 'package:wordini/Providers/otherproviders.dart';
import 'package:wordini/file_handling.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:wordini/notification_controller.dart';
import 'package:wordini/widgets.dart';
import 'package:wordini/word_functions.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends ConsumerState<SettingsPage> {
  final LoadingOverlay loadingOverlay = LoadingOverlay();
  @override
  void dispose() {
    loadingOverlay.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final Map<String, bool>? notificationSettings = ref.watch(notificationSettingsProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          settingsHeader('Account'),
          const SizedBox(height: 8),
          _buildSettingsTile(
            icon: Icons.person,
            label: 'Account',
            function: () async {
              loadingOverlay.showLoadingOverlay(context);
              User? user = FirebaseAuth.instance.currentUser;
              if (user != null){
                // await reAuthUser(user, context);
                user = FirebaseAuth.instance.currentUser;
                if (context.mounted){
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AccountPage(accountDetails: user!),
                    ),
                  );
                }
                loadingOverlay.removeLoadingOverlay();
              }else{
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SignInPage(),
                  ),
                );
                loadingOverlay.removeLoadingOverlay();
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
              ref.invalidate(wordDataFutureProvider);
            },
          ),
          _buildSettingsTile(
            icon: Icons.restart_alt,
            label: 'Reset Data',
            function: () async {
              await resetData(context, ref);
            },
          ),
          _buildSettingsTile(
            icon: Icons.download_rounded,
            label: 'Import CSV',
            function: () async {
              loadingOverlay.showLoadingOverlay(context);
              await processCsvRows(context, ref.read(wordDataProvider).keys.toList());
              if (mounted){
                loadingOverlay.removeLoadingOverlay();
              }
              else{
                loadingOverlay.dispose();
              }
              ref.invalidate(wordDataFutureProvider);
            },
          ),
          settingsHeader('Utilities'),
          const SizedBox(height: 8),
          _buildSettingsTile(
            icon: Icons.local_library,
            label: 'Archived Words',
            function: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ArchivedWordsScreen(),
              ),
            )
          ),
          settingsHeader('Accessability'),
          const SizedBox(height: 8),
          _buildSettingsTile(
            icon: Icons.notifications,
            label: 'Notification Permissions',
            function: () async{
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) {
                  return _NotificationSettingsSheet(settings: notificationSettings ?? {},);
                },
              );
            },
          ),
          _buildSettingsTile(
            icon: Icons.color_lens,
            label: 'Main Theme Color',
            function: () async {
              final Color? newColor = await _pickColor(context);
              if (newColor != null){
                ref.read(themeProvider.notifier).setTheme(newColor);
              }
            }
          ),
        ],
      )
    );
  }
  Future<Color?> _pickColor(BuildContext context) async {
    final selectedColor = await showDialog<Color>(
      context: context,
      builder: (context) {
        Color tempColor = ref.read(themeProvider);

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Pick a color!'),
              content: SingleChildScrollView(
                child: ColorPicker(
                  pickerColor: tempColor,
                  onColorChanged: (color) {
                    setState(() => tempColor = color);
                  },
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Reset color'),
                  onPressed: () {
                    setState(() => tempColor = Colors.blue);
                  },
                ),
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.pop(context, null),
                ),
                TextButton(
                  child: const Text('Select'),
                  onPressed: () => Navigator.pop(context, tempColor),
                ),
              ],
            );
          },
        );
      },
    );

    return selectedColor;
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

Future<void> processCsvRows(context, List existingWords) async {
  final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv']);

  if (result != null) {
    final file = File(result.files.single.path!);
    final content = await file.readAsString();
    final rows = const CsvToListConverter().convert(content);
    
    final allTags = await gatherTags();
    for (var row in rows) {
      String word = row[0].toString();
      // final String definition = row[1].toString();
      if (existingWords.contains(word)) continue; // skip iteration if its already in words
      
      final Map wordDetails = await getWordDetails(word.toLowerCase());
      word = wordDetails['word']; // ! not safe
      if (wordDetails.isNotEmpty) {
        debugPrint('Word exists: $word');
        writeKey(word, wordDetails);
      } else { // ! needs work
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

class _NotificationSettingsSheet extends ConsumerWidget {
  final Map<String, bool> settings;

  const _NotificationSettingsSheet({required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationSettings = ref.watch(notificationSettingsProvider).value ?? settings;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Notification Settings',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ...notificationSettings.keys.map((type) {
            return SwitchListTile(
              title: Text(type),
              value: notificationSettings[type]!,
              onChanged: (bool value) {
                ref.read(notificationSettingsProvider.notifier).updateValue(type, value);
                
                if (value) {
                  initializeNotifications(askPermission: true);
                } else {
                  turnNotificaitonsOff();
                }
              },
            );
          }),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}