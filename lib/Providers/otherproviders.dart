import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordini/file_handling.dart' as file;

final wordDataFutureProvider = FutureProvider<Map>((ref) async {
  return file.readData();
});

class WordDataWriteableNotifier extends Notifier<Map> {

  @override
  Map build() {
    final asyncData = ref.watch(wordDataFutureProvider);

    return asyncData.when(
      data: (data) => data,
      loading: () => {},
      error: (_, __) => {},
    );
  }

  void updateValue(String word, dynamic value) {
    state = {...state, word: value};
    file.writeKey(word, value);
  }
  void removeKey(String word) {
    state = {...state}..remove(word);
    file.deleteKey(word);
  }
}

final wordDataProvider = NotifierProvider<WordDataWriteableNotifier, Map>(WordDataWriteableNotifier.new);

final searchTermProvider = StateProvider<String>((ref) => '');

final filtersProvider = StateProvider<Map>((ref) => {
  'wordTypes': <String>{},
  'wordTypeMode': 'any',
  'selectedTags': <String>{},
  'selectedTagsMode': 'any',
  'sortBy': 'Alphabetical',
  'sortOrder': 'Ascending'
});

final showBarProvider = StateProvider<bool>((ref) => false);


final futureSettingsDataProvider = FutureProvider<Map>((ref) async {
  return file.readData(path: 'settings');
});

class SettingsDataNotifier extends Notifier<Map> {

  @override
  Map build() {
    final asyncData = ref.watch(futureSettingsDataProvider);

    return asyncData.when(
      data: (data) => data,
      loading: () => {},
      error: (_, __) => {},
    );
  }

  void updateValue(String key, dynamic value) {
    state = {...state, key: value};
  }
}

final settingsProvider = NotifierProvider<SettingsDataNotifier, Map>(SettingsDataNotifier.new);

final archivedWordsDataProvider = FutureProvider<Map>((ref) async {
  return file.readData(path: 'archivedWords');
});

class ArchivedWordsNotifier extends Notifier<Map> {
  @override
  Map build() {
    final asyncData = ref.watch(archivedWordsDataProvider);

    return asyncData.when(
      data: (data) => data,
      loading: () => {},
      error: (_, __) => {},
    );
  }

  void updateValue(String key, dynamic value) {
    state = {...state, key: value};
    file.writeKey(key, value, path: 'archivedWords');
  }
  
  void removeKey(String key) {
    state = {...state}..remove(key);
    file.deleteKey(key, path: 'archivedWords');
  }
}

final archivedWordsProvider = NotifierProvider<ArchivedWordsNotifier, Map>(ArchivedWordsNotifier.new);


class ThemeNotifier extends Notifier<Color> {
  @override
  Color build() {
    // default
    _loadTheme();
    return Colors.blue;
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt('themeColor');
    if (colorValue != null) {
      state = Color(colorValue);
    }
  }

  Future<void> setTheme(Color color) async {
    state = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeColor', color.toARGB32());
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, Color>(() {
  return ThemeNotifier();
});

class NotificationSettings extends AsyncNotifier<Map<String, bool>> {
  @override
  Future<Map<String, bool>> build() async {
    final data = await file.readData(path: 'notificationSettings');
    final settings = Map<String, bool>.from(data);
    final notificationsEnabled = await Permission.notification.isGranted;
    List boilerData = ['Quiz Reminders'];

    for (String key in boilerData) {
      if (!settings.containsKey(key)) {
        settings[key] = notificationsEnabled;
        await file.writeKey(key, settings[key], path: 'notificationSettings');
      }
    }
    return settings;
  }

  Future<void> updateValue(String key, bool value) async {
    final oldState = await future;
    final newState = {...oldState, key: value};
    state = AsyncData(newState);
    
    try {
      await file.writeKey(key, value, path: 'notificationSettings');
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
  bool getValue(key){
    return state.value?[key] ?? false;
  }
}

final notificationSettingsProvider = AsyncNotifierProvider<NotificationSettings, Map<String, bool>>(() {
  return NotificationSettings();
});