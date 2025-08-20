import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wordini/file_handling.dart';

final wordDataFutureProvider = FutureProvider<Map>((ref) async {
  return readData();
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
}

final wordDataProvider = NotifierProvider<WordDataWriteableNotifier, Map>(WordDataWriteableNotifier.new);