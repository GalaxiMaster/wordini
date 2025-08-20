// home.dart

// This provider remains the same.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wordini/Pages/home.dart';

final appDataProvider = FutureProvider<Map>((ref) async {
  return fetchInputData();
});

// 1. Define the generic Notifier that uses a parameter.
// FamilyNotifier<State_Type, Parameter_Type>
class WritableDataNotifier extends FamilyNotifier<Map, String> {

  @override
  Map build(String arg) {
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
}

final writableDataProvider = NotifierProvider.family<WritableDataNotifier, Map, String>(WritableDataNotifier.new);