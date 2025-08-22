import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  void updateValue(String key, dynamic value) {
    state = {...state, key: value};
  }
  void removeKey(String word) {
    final newState = {...state};
    newState.remove(word);
    state = newState;
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