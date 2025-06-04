import 'package:flutter/material.dart';
import 'package:vocab_app/file_handling.dart';
import 'package:vocab_app/notification_controller.dart';
import 'package:vocab_app/widgets.dart';
import 'package:vocab_app/word_functions.dart';

class Quizzes extends StatefulWidget {
  const Quizzes({super.key});
  @override
  // ignore: library_private_types_in_public_api
  _QuizzesState createState() => _QuizzesState();
}

class _QuizzesState extends State<Quizzes> {
  Future<Map>? words; // Make nullable to avoid LateInitializationError
  int _currentIndex = 0;
  Map currentWord = {};
  // session stats
  int questionsDone = 0;
  int questionsRight = 0;
  Map rawWords = {};

  final TextEditingController entryController = TextEditingController();
  final FocusNode _entryFocusNode = FocusNode();
  @override
  void initState() {
    super.initState();
    readData().then((data) {
      rawWords = data; // store the raw data for later use
      setState(() {
        words = Future.value(randomise(_gatherSelectedDefinitions(data)));
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _entryFocusNode.requestFocus();
    });
  }

  // Gather selected definitions from the data (returns a List)
  List<Map> _gatherSelectedDefinitions(Map words) {
    List<Map> selectedWords = [];
    for (var word in words.entries) {
      Map wordData = Map<String, dynamic>.from(word.value);
      wordData.remove('entries');
      for (var speechType in word.value['entries'].entries) {
        if (speechType.value['selected'] == true) {
          Map<String, dynamic> merged = Map<String, dynamic>.from(wordData);
          merged['attributes'] = Map<String, dynamic>.from(speechType.value);
          selectedWords.add(merged);
        }
      }
    }
    return selectedWords;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map>(
        future: words,
        builder: (context, snapshot) {
          if (words == null) {
            // words is not initialized yet
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading data ${snapshot.error}'));
          } else if (snapshot.hasData) {
            Map words = snapshot.data!;
            if (words.isEmpty) {
              return const Center(child: Text('No words added'));
            }
            currentWord = words[words.keys.elementAt(_currentIndex)];
            return Stack(
              children: [
                Positioned(
                  top: 5,
                  child: SizedBox(
                    height: 50,
                    width: MediaQuery.of(context).size.width,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.lightbulb),
                          onPressed: () {
                            String message;
                            try {
                              message = currentWord['entries'].entries.first.value['details'].first['definitions'].first.first['example'].first;
                            } on StateError {
                              message = 'No example available';
                            }
                            errorOverlay(context, message);
                          },
                        ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            '$questionsRight / $questionsDone',
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (_currentIndex < words.length - 1)
                          IconButton(
                            icon: const Icon(Icons.arrow_forward),
                            onPressed: () {
                              setState(() {
                                _currentIndex++;
                              });
                              entryController.clear();
                              questionsDone++; // up counter in the top right
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          capitalise(currentWord['word']),
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          focusNode: _entryFocusNode,
                          controller: entryController,
                          decoration: InputDecoration(
                            labelStyle: TextStyle(
                              color: Colors.grey[400],
                            ),
                            labelText: 'Enter definition',
                          ),
                          onSubmitted: (value) async {
                            value = value.trim();
                            if (value.toLowerCase() == currentWord['word'].toLowerCase()) return; // ADD error message for this

                            bool? correct = await checkDefinition(currentWord['word'], value, '', context);

                            if (correct == null) return;

                            if (correct) {
                              if (_currentIndex < words.length - 1) {
                                setState(() {
                                  _currentIndex++;
                                });
                                entryController.clear();
                              }
                              removeNotif(currentWord['word']);
                              questionsRight++;
                              // TODO some sort of correct answer animation
                            } else {
                              errorOverlay(context, 'Wrong answer');
                            }
                            questionsDone++;
                            String partOfSpeech = currentWord['attributes']['partOfSpeech'] ?? 'unknown';
                            words[currentWord['word']]['attributes']['inputs'] ??= [];
                            words[currentWord['word']]['attributes']['inputs'].add({
                              'guess': value,
                              'correct': correct,
                              'date': DateTime.now().toString(),
                            });
                            rawWords[currentWord['word']]['entries'][partOfSpeech] = words[currentWord['word']]['attributes'];

                            writeData(rawWords, append: false);
                          },
                        ),
                      ],
                    ),
                  ),
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

  Map randomise(List<Map> data) {
    Map weightings = generateWeightings(data);
    data.sort((a, b) {
      final aWeight = weightings[a['word']]?['weight'] ?? 1.0;
      final bWeight = weightings[b['word']]?['weight'] ?? 1.0;
      return aWeight.compareTo(bWeight);
    });
    return { for (var w in data) w['word']: w };
  }

  Map generateWeightings(List<Map> data) {
    double maxChecked = 0, maxRight = 0, maxPct = 0;
    Map<String, dynamic> weightings = {};
    for (var wordData in data) {
      final key = wordData['word'];
      int checked = wordData['inputs']?.length ?? 0;
      int right = wordData['inputs']?.where((e) => e['correct'] == true).length ?? 0;
      DateTime? lastChecked = checked != 0 ? DateTime.tryParse(wordData['inputs']?.last['date'] ?? '') : null;
      double pct = checked > 0 ? (right / checked) : 0.0;
      if (checked > maxChecked) maxChecked = checked.toDouble();
      if (right > maxRight) maxRight = right.toDouble();
      if (pct > maxPct) maxPct = pct;
      weightings[key] = {
        'timesChecked': checked,
        'timesRight': right,
        'lastChecked': lastChecked,
        'percentage': pct,
      };
    }
    for (var wordData in data) {
      final key = wordData['word'];
      var w = weightings[key];
      double value = w['timesChecked'] == 0
          ? 1
          : (w['timesChecked'] / (maxChecked == 0 ? 1 : maxChecked) / 2)
            + (w['percentage'] / (maxPct == 0 ? 1 : maxPct) / 2)
            + ((w['lastChecked'] != null) ? (w['lastChecked'] as DateTime).difference(DateTime.now()).inDays / 60 : 0);
      weightings[key]['weight'] = value.clamp(0, 0.99);
    }
    return weightings;
  }
}
