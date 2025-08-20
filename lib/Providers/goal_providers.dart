// home.dart

// This provider remains the same.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wordini/Pages/home.dart';

final appDataProvider = FutureProvider<Map>((ref) async {
  return fetchInputData();
});

class WritableDataNotifier extends FamilyNotifier<Map, String> {

  @override
  Map build(String arg) {
    // 'statistics', 'homePage', '
    final asyncData = ref.watch(appDataProvider);

    return asyncData.when(
      data: (data) => data[arg] as Map? ?? {}, // Use arg to get the specific sub-map
      loading: () => {},
      error: (_, __) => {},
    );
  }

  void updateValue(String key, dynamic value) {
    state = {...state, key: value};
  }
  void incrimentKey(key){
    if (state[key] is num){
      state[key]++;
    }
  }
}

final writableDataProvider = NotifierProvider.family<WritableDataNotifier, Map, String>(WritableDataNotifier.new);