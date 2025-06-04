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
  Future<List>? words; // Make nullable to avoid LateInitializationError
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
      body: FutureBuilder<List>(
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
            List words = snapshot.data!;
            if (words.isEmpty) {
              return const Center(child: Text('No words added'));
            }
            currentWord = words.elementAt(_currentIndex);
            String partOfSpeech = currentWord['attributes']['partOfSpeech'] ?? 'unknown';
            return Stack(
              children: [
                Positioned(
                  top: 25,
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
                              message = currentWord['attributes']['details'].first['definitions'].first.first['example'].first;
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
                              rawWords[currentWord['word']]['entries'][partOfSpeech]['inputs'] ??= [];
                              rawWords[currentWord['word']]['entries'][partOfSpeech]['inputs'].insert(0, {
                                'skipped': true,
                                'date': DateTime.now().toString(),
                              });

                              writeData(rawWords, append: false);
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
                        Column(
                          children: [
                            Text(
                              capitalise(currentWord['word']),
                              style: const TextStyle(fontSize: 26),
                            ),
                            Text(
                              capitalise(partOfSpeech),
                              style: TextStyle(
                                fontSize: 18,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
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
                            rawWords[currentWord['word']]['entries'][partOfSpeech]['inputs'] ??= [];
                            rawWords[currentWord['word']]['entries'][partOfSpeech]['inputs'].insert(
                              0, 
                              {
                                'guess': value,
                                'correct': correct,
                                'date': DateTime.now().toString(),
                              }
                            );

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

  List randomise(List<Map> data) {
    Map weightings = generateWeightings(data);
    data.sort((a, b) {
      final aWeight = weightings[a['word']]?['weight'] ?? 1.0;
      final bWeight = weightings[b['word']]?['weight'] ?? 1.0;
      return bWeight.compareTo(aWeight);
    });
    return data;
  }

  Map generateWeightings(List<Map> data) {
    double maxChecked = 0, maxRight = 0, maxPct = 0;
    Map<String, dynamic> weightings = {};
    for (var wordData in data) {
      final key = '${wordData['word']} (${wordData['attributes']['partOfSpeech']})';
      int checked = wordData['attributes']['inputs']?.length ?? 0;
      int right = wordData['attributes']['inputs']?.where((e) => e['correct'] == true).length ?? 0;
      DateTime? lastChecked = checked != 0 ? DateTime.tryParse(wordData['attributes']['inputs']?.last['date'] ?? '') : null;
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
    // ADD skipping counts & ability to spread to 
    for (var word in weightings.entries) {
      final key = word.key;
      var w = weightings[key];
      double value = w['timesChecked'] == 0
          ? 1.1
          : (((1/w['timesChecked']) / (maxChecked == 0 ? 1 : maxChecked) / 4)
            + ((1/w['percentage']) / (maxPct == 0 ? 1 : maxPct) / 4)
            + ((w['lastChecked'] != null) ? (w['lastChecked'] as DateTime).difference(DateTime.now()).inDays / 60 : 0)).clamp(0, 1);
      weightings[key]['weight'] = value;
    }
    return weightings;
  }
}
