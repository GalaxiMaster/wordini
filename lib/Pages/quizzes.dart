import 'package:flutter/material.dart';
import 'package:vocab_app/file_handling.dart';
import 'package:vocab_app/notification_controller.dart';
import 'package:vocab_app/widgets.dart';
import 'package:vocab_app/word_functions.dart';

class Quizzes extends StatefulWidget {
  const Quizzes({super.key});
  @override
  QuizzesState createState() => QuizzesState();
}

class QuizzesState extends State<Quizzes> {
  Future<List>? words; // Make nullable to avoid LateInitializationError
  int _currentIndex = 0;
  Map currentWord = {};
  // session stats
  int questionsDone = 0;
  int questionsRight = 0;
  Map<String, dynamic> rawWords = {};

  final TextEditingController entryController = TextEditingController();
  final FocusNode _entryFocusNode = FocusNode();
  @override
  void initState() {
    super.initState();
    readData().then((data) {
      rawWords = data; // store the raw data for later use
      _gatherSelectedDefinitions(data).then((selectedDefs) {
        setState(() {
          words = Future.value(randomise(selectedDefs));
        });
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _entryFocusNode.requestFocus();
    });
  }
    @override
  void dispose() {
    entryController.dispose();
    _entryFocusNode.dispose();
    super.dispose();
  }

  // Gather selected definitions from the data (returns a List)
  Future<List<Map>> _gatherSelectedDefinitions(Map words) async{
    Map inputs = await readData(path: 'inputs');
    List<Map> selectedWords = [];
    for (var word in words.entries) {
      Map wordData = Map<String, dynamic>.from(word.value);
      wordData.remove('entries');
      for (var speechType in word.value['entries'].entries) {
        if (speechType.value['selected'] == true) {
          Map<String, dynamic> merged = Map<String, dynamic>.from(wordData);
          merged['attributes'] = Map<String, dynamic>.from(speechType.value);
          merged['attributes']['inputs'] = inputs[word.key]?[speechType.key] ?? [];
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
                              List examples = [];
                              final details = currentWord['attributes']['details'] ?? {};
                              details.forEach((value) {
                                final definitions = value['definitions'] ?? [];
                                for (var defGroup in definitions) {
                                  for (var subGroup in defGroup) {
                                    examples += subGroup['example'];
                                  }
                                }
                              });
                              message = examples[0];
                              // message = currentWord['attributes']['details'].first['definitions'].first.first['example'].first;
                            } on RangeError {
                              message = 'No example available';
                            }
                            errorOverlay(context, message, duration: Duration(seconds: 5), color: Color.fromARGB(255, 30, 30, 30));
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
                              addInputEntry(
                                currentWord['word'], 
                                currentWord['attributes']['partOfSpeech'], 
                                {
                                  'skipped': true,
                                  'date': DateTime.now().toString(),
                                }
                              );
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

                            bool? correct = await checkDefinition(currentWord['word'], value, currentWord['attributes']['partOfSpeech'], context);

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
                            addInputEntry(
                              currentWord['word'],
                              currentWord['attributes']['partOfSpeech'], 
                              {
                                'guess': value,
                                'correct': correct,
                                'date': DateTime.now().toString(),
                              }
                            );
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
      final aWeight = weightings['${a['word']} (${a['attributes']['partOfSpeech']})']?['weight'] ?? 1.0;
      final bWeight = weightings['${b['word']} (${b['attributes']['partOfSpeech']})']?['weight'] ?? 1.0;
      return bWeight.compareTo(aWeight);
    });
    return data;
  }

  Map<String, dynamic> generateWeightings(List<Map> data) {
    double maxChecked = 0, maxRight = 0, maxPct = 0;
    Map<String, dynamic> weightings = {};
    final now = DateTime.now();

    data.sort((a, b) => DateTime.parse(a['dateAdded']).compareTo(DateTime.parse(b['dateAdded'])));

    for (var wordData in data) {
      final key = '${wordData['word']} (${wordData['attributes']['partOfSpeech']})';
      final inputs = wordData['attributes']['inputs'] ?? [];

      int checked = inputs.length;
      int right = inputs.where((e) => e['correct'] == true).length;
      DateTime? lastChecked = checked > 0 ? DateTime.tryParse(inputs.last['date'] ?? '') : null;
      bool lastWasSkip = inputs.isNotEmpty && (inputs.last['skip'] == true);
      double pct = checked > 0 ? (right / checked) : 0.0;

      if (checked > maxChecked) maxChecked = checked.toDouble();
      if (right > maxRight) maxRight = right.toDouble();
      if (pct > maxPct) maxPct = pct;

      weightings[key] = {
        'timesChecked': checked,
        'timesRight': right,
        'lastChecked': lastChecked,
        'percentage': pct,
        'lastWasSkip': lastWasSkip,
      };
    }

    for (var entry in weightings.entries) {
      final w = entry.value;
      int checked = w['timesChecked'];
      double pct = w['percentage'];
      DateTime? lastChecked = w['lastChecked'];
      bool lastWasSkip = w['lastWasSkip'];

      double weight;

      // Most important: new words
      if (checked == 0) {
        weight = 1.0;
      } 
      // Treat skipped words as newly added if last skip was ≥ 12 hours ago
      else if (lastWasSkip && lastChecked != null && now.difference(lastChecked).inHours >= 12) {
        weight = 1.0;
      } 
      else {
        // Scaled inverses for fewer checks and lower accuracy
        double invCheck = 1 - (checked / (maxChecked == 0 ? 1 : maxChecked));
        double invPct = 1 - (pct / (maxPct == 0 ? 1 : maxPct));

        // Recency factor (0.0–0.3 range): more recent → lower weight
        double timeDecay = lastChecked != null ? 
            (now.difference(lastChecked).inDays.clamp(0, 30) / 30) * 0.3 : 
            0.3;

        weight = (invCheck * 0.4) + (invPct * 0.3) + timeDecay;
        weight = weight.clamp(0.0, 1.0);
      }

      w['weight'] = weight;
    }

    return weightings;
  }
}