import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordini/file_handling.dart' as file;

final wordDataFutureProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return Map<String, dynamic>.from(await file.readData());
});

class WordDataWriteableNotifier extends Notifier<Map<String, dynamic>> {
  @override
  Map<String, dynamic> build() {
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

final wordDataProvider =
    NotifierProvider<WordDataWriteableNotifier, Map<String, dynamic>>(
  WordDataWriteableNotifier.new,
);
class SearchTermNotifier extends Notifier<String> {
  @override
  String build() => '';
 
  void set(String value) => state = value;
 
  void clear() => state = '';
}
 
final searchTermProvider =
    NotifierProvider<SearchTermNotifier, String>(SearchTermNotifier.new);
 
// ---------------------------------------------------------------------
// Filters
// ---------------------------------------------------------------------
 
class FiltersNotifier extends Notifier<Map<String, dynamic>> {
  static const Map<String, dynamic> _defaults = {
    'wordTypes': <String>{},
    'wordTypeMode': 'any',
    'selectedTags': <String>{},
    'selectedTagsMode': 'any',
    'sortBy': 'Date Added', // todo change to enum
    'sortOrder': 'Ascending',
  };
 
  @override
  Map<String, dynamic> build() => _defaults;
 
  /// Replace a single key, keeping the rest of the map intact.
  /// Always creates a new map so watchers actually get notified.
  void updateFilter(String key, dynamic value) {
    state = {...state, key: value};
  }
 
  void toggleWordType(String type) {
    final current = Set<String>.from(state['wordTypes'] as Set<String>);
    current.contains(type) ? current.remove(type) : current.add(type);
    updateFilter('wordTypes', current);
  }
 
  void toggleTag(String tag) {
    final current = Set<String>.from(state['selectedTags'] as Set<String>);
    current.contains(tag) ? current.remove(tag) : current.add(tag);
    updateFilter('selectedTags', current);
  }
 
  void setSortBy(String value) => updateFilter('sortBy', value);
 
  void setSortOrder(String value) => updateFilter('sortOrder', value);
 
  void reset() => state = _defaults;
}
 
final filtersProvider = NotifierProvider<FiltersNotifier, Map<String, dynamic>>(
  FiltersNotifier.new,
);
 
class ShowBarNotifier extends Notifier<bool> {
  @override
  bool build() => false;
 
  void show() => state = true;
 
  void hide() => state = false;
 
  void toggle() => state = !state;
}
 
final showBarProvider =
    NotifierProvider<ShowBarNotifier, bool>(ShowBarNotifier.new);
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

  bool getValue(key) {
    return state.value?[key] ?? false;
  }
}

final notificationSettingsProvider = AsyncNotifierProvider<NotificationSettings, Map<String, bool>>(() {
  return NotificationSettings();
});
