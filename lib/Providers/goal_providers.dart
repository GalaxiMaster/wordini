import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wordini/Pages/home.dart';
import 'package:wordini/Providers/otherproviders.dart';
import 'package:wordini/file_handling.dart' as file;

final futureInputDataProvider = FutureProvider<Map>((ref) async {
  return file.readData(path: 'inputs');
});

class InputDataNotifier extends Notifier<Map> {
  @override
  Map build() {
    final asyncData = ref.watch(futureInputDataProvider);

    return asyncData.when(
      data: (data) => data,
      loading: () => {},
      error: (_, __) => {},
    );
  }
  void removeEntry(word, speechPart, index){
    Map data = state[word];
    data[speechPart].removeAt(index);
    state = {...state, word: data};
    file.writeKey(word, data, path: 'inputs');
  }
  
  Future<void> addInputEntry(String word, String partOfSpeech, Map entry) async{
    Map data = state[word] ?? {};
    data[partOfSpeech] ??= [];
    data[partOfSpeech].insert(0, entry);
    state = {...state, word: data};
    file.writeKey(word, data, path: 'inputs');
  }
}
final inputDataProvider = NotifierProvider<InputDataNotifier, Map>(InputDataNotifier.new);

class StatisticsDataNotifier extends Notifier<Map> {
  @override
  Map build() {
    final asyncData = ref.watch(futureInputDataProvider);

    return asyncData.when(
      data: (data) {
        final int week = getWeekNumber(DateTime.now());

        int wordsGuessed = 0;
        int speechTypesGuessed = 0;
        int totalGuesses = 0;
        int totalSkips = 0;
        int correctGuesses = 0;
        final Map<String, int> wordGuesses = {};
        int guessesThisWeek = 0;
        int guessesToday = 0;

        for (final MapEntry word in data.entries) {
          wordsGuessed++;
          wordGuesses[word.key] = (wordGuesses[word.key] ?? 0) + 1;

          if (word.value is Map) {
            final Map speechTypes = word.value;
            for (final MapEntry speechType in speechTypes.entries) {
              speechTypesGuessed++;
              for (Map guess in speechType.value){
                if (guess['correct'] != null){
                  final int guessWeek = getWeekNumber(DateTime.parse(guess['date']));
                  if (guessWeek == week){
                    guessesThisWeek += 1;
                  }
                  if (isSameDay(DateTime.parse(guess['date']), DateTime.now())){
                    guessesToday += 1;
                  }
                  correctGuesses++;
                }
                if (guess['skipped'] ?? false){
                  totalSkips++;
                } else {
                  totalGuesses++;
                }
              }
            }
          }
        }
        return {
          'wordsGuessed': wordsGuessed,
          'speechTypesGuessed': speechTypesGuessed,
          'totalGuesses': totalGuesses,
          'totalSkips': totalSkips,
          'correctGuesses': correctGuesses,
          'wordGuesses': wordGuesses,
          'guessesThisWeek': guessesThisWeek,
          'guessesToday': guessesToday,
        };
      },
      loading: () => {},
      error: (_, __) => {},
    );
  }

  void updateValue(String key, dynamic value) {
    state = {...state, key: value};
  }
}

final statisticsDataProvider = NotifierProvider<StatisticsDataNotifier, Map>(StatisticsDataNotifier.new);

class WordsThisWeekDataNotifier extends Notifier<int> {
  @override
  int build() {
    final data = ref.watch(wordDataProvider);

    final int week = getWeekNumber(DateTime.now());

    int wordsThisWeek = 0;
    
    for (MapEntry word in data.entries){
      final int wordWeek = getWeekNumber(DateTime.parse(word.value['dateAdded']));
      if (wordWeek == week){
        wordsThisWeek += 1;
      }
    }
    return wordsThisWeek;
  }

  void incriment() {
    state = state+=1;
  }
}

final wordsThisWeekDataProvider = NotifierProvider<WordsThisWeekDataNotifier, int>(WordsThisWeekDataNotifier.new);