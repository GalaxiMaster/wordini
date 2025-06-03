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
  late Future<Map> words;
  int _currentIndex = 0;
  Map currentWord = {};
  // session stats
  int questionsDone = 0;
  int questionsRight = 0;
  final TextEditingController entryController = TextEditingController();
  @override
  void initState() {
    super.initState();
    final data = readData();
    words = randomise(data);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
      future: words,
      builder: (context, snapshot) {
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
                top: 0,
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
                      Spacer(),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          '$questionsRight / $questionsDone',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (_currentIndex < words.length -1)
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
                )
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        capitalise(currentWord['word']),
                        style: TextStyle(fontSize: 24),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: entryController,
                        decoration: InputDecoration(
                          labelText: 'Search for a word',
                        ),
                        onSubmitted: (value) async{
                          value = value.trim();
                          if (value.toLowerCase() == currentWord['word'].toLowerCase()) return;

                          bool? correct = await checkDefinition(currentWord['word'], value, '', context);//currentWord['definitions'].first['definition']
                          
                          if (correct == null) return;

                          if (correct) { // ! On Correct
                            // move to next word
                            if (_currentIndex < words.length -1) {
                              setState(() {
                                _currentIndex++;
                              });
                              entryController.clear();
                            }
                            removeNotif(currentWord['word']);
                            questionsRight++;
                            // TODO some sort of correct answer animation
                          }
                          else{
                            errorOverlay(context, 'Wrong answer');
                          }
                          questionsDone++;
                          words[currentWord['word']]['inputs'] ??= [];
                          words[currentWord['word']]['inputs'].add({
                            'guess': value,
                            'correct': correct,
                            'date': DateTime.now().toString(),
                          });

                          writeData(words, append: false);
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
  
  Future<Map> randomise(Future<Map> data) {
    // return data.then((value) {
    //   List keys = value.keys.toList();
    //   keys.shuffle();
    //   Map<String, dynamic> shuffledData = {};
    //   for (String key in keys) {
    //     shuffledData[key] = value[key];
    //   }
    //   return shuffledData;
    // });
    return data.then((words) {
        Map weightings = generateWieightings(words);
        // Create a list of keys sorted by their weighting
        List sortedKeys = weightings.keys.toList()
          ..sort((a, b) => (weightings[a]['weight'] as double).compareTo(weightings[b]['weight'] as double));
        // Build a new map with sorted keys
        Map sortedWords = { for (var k in sortedKeys) k : words[k] };
        return sortedWords;
    });
  }
  Map generateWieightings(Map data){
    // last time checked
    // last time value
    // how many times checked / right percentage
    double doubleMaxTimesChecked = 0;
    double doubleMaxTimesRight = 0;
    double doubleMaxPercentage = 0;
    Map weightings = {};
    for (var key in data.keys) {

      int timesChecked = data[key]['inputs']?.length ?? 0;
      int timesRight = data[key]['inputs']?.where((entry) => entry['correct'] == true).length ?? 0;
      DateTime? lastChecked;
      bool? lastTimeValue;
      if (timesChecked != 0){
        lastChecked = DateTime.parse(data[key]['inputs']?.last['date'] ?? '');
        lastTimeValue = data[key]['inputs']?.last['correct'];
      }

      double percentage = timesChecked > 0 ? (timesRight / timesChecked) : 0.0;
      if (timesChecked > doubleMaxTimesChecked) {
        doubleMaxTimesChecked = timesChecked.toDouble();
      }
      if (timesRight > doubleMaxTimesRight) {
        doubleMaxTimesRight = timesRight.toDouble();
      }
      if (percentage > doubleMaxPercentage) {
        doubleMaxPercentage = percentage;
      }
      weightings[key] = {
        'timesChecked': timesChecked,
        'timesRight': timesRight,
        'lastChecked': lastChecked,
        'lastTimeValue': lastTimeValue,
        'percentage': percentage,
      };
    }

    
    for (MapEntry weight in weightings.entries) {
      late double value;
      if (weight.value['timesChecked'] == 0){
        value = 1;
      } else{
        value = weight.value['timesChecked'] / doubleMaxTimesChecked / 2;
        value += weight.value['percentage'] / doubleMaxPercentage / 2;
        value += weight.value['lastChecked']!.difference(DateTime.now()).inDays / 60;
        value = value.clamp(0, 0.99);
      }
      weightings[weight.key]['weight'] = value;
    }
    return weightings;
  }
}