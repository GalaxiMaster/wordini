// import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:vocab_app/Pages/add_word.dart';
import 'package:vocab_app/Pages/quizzes.dart';
import 'package:vocab_app/Pages/settings.dart';
import 'package:vocab_app/Pages/statistics_page.dart';
import 'package:vocab_app/Pages/word_list.dart';
import 'package:vocab_app/file_handling.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  int _currentIndex = 1;
  final List<Widget> _pages = [
    WordList(),
    HomePageContent(),
    Quizzes(),
  ];
  @override
  void initState() {
    super.initState();
        // showInstantNotification(
    //   title: 'YOU JUST GOT NOTIFIED', 
    //   description: 'notified', 
    //   androidPlatformChannelSpecifics: NotificationType.wordReminder.details, 
    //   payload: 'wordReminder'
    // );
    // scheduleNotification(
    //   title: 'YOU JUST GOT NOTIFIED', 
    //   description: 'notified', 
    //   duration: Duration(seconds: 1), 
    //   androidPlatformChannelSpecifics: NotificationType.wordReminder.details, 
    //   payload: 'wordReminder'
    // );
  }
  @override
  Widget build(BuildContext context) {
    // resetData(true, false, false);
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        indicatorColor: const Color.fromARGB(255, 112, 173, 252),
        selectedIndex: _currentIndex,
        destinations: const <Widget>[
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            label: 'Words list',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.home),
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.quiz),
            label: 'Questions',
          ),
        ],
      ),
      body: _pages[_currentIndex],
    );
  }
}

class HomePageContent extends StatefulWidget {
  const HomePageContent({super.key});
  @override
  HomePageContentState createState() => HomePageContentState();
}

class HomePageContentState extends State<HomePageContent> {
  @override
  void initState() {
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: fetchInputData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error loading data'));
        } else if (snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(
              title: Center(child: Text('The Vocab Lab')),
              automaticallyImplyLeading: false,
              leading: IconButton(
                onPressed: (){
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SettingsPage())
                  );
                }, 
                icon: Icon(Icons.settings)
              ),
              actions: [
                IconButton(
                  onPressed: (){
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => WordGameStatsScreen(gameData: snapshot.data!,))
                    );
                  }, 
                  icon: Icon(Icons.bar_chart)
                ),
              ],
            ),
            body: SizedBox(
              height: double.infinity,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(25),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.green
                      ),
                      width: double.infinity,
                      height: 100,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(''),
                        ),
                      )
                    ),
                  ),
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: FloatingActionButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddWord(),
                            )
                        );
                      },
                      backgroundColor: Colors.blue,
                      child: Text(
                        "+",
                        style: TextStyle(
                          fontSize: 30,
                          color: Colors.white,
                        ),
                      ),
                    )
                  )
                ],
              ),
            ),
          );
        } else {
          return const Center(child: Text('No data available'));
        }
      },
    );
  }
  
  Future<GameStats> fetchInputData() async {
    final Map<String, dynamic> data = await readData(path: 'inputs');

    int wordsGuessed = 0;
    int speechTypesGuessed = 0;
    int totalGuesses = 0;
    int totalSkips = 0;
    int correctGuesses = 0;
    final Map<String, int> wordGuesses = {};

    for (final MapEntry<String, dynamic> word in data.entries) {
      wordsGuessed++;
      wordGuesses[word.key] = (wordGuesses[word.key] ?? 0) + 1;

      if (word.value is Map) {
        final Map speechTypes = word.value;
        for (final MapEntry speechType in speechTypes.entries) {
          speechTypesGuessed++;
          for (Map guess in speechType.value){
            if (guess['correct'] ?? false){
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

    int averageTimesGuessed = wordsGuessed > 0
        ? wordGuesses.values.reduce((a, b) => a + b) ~/ wordsGuessed
        : 0;
    final GameStats gameStats = GameStats(
      wordsGuessed: wordsGuessed,
      speechTypesGuessed: speechTypesGuessed,
      totalGuesses: totalGuesses,
      totalSkips: totalSkips,
      correctGuesses: correctGuesses,
      wordGuesses: wordGuesses
    );
    return gameStats;
  }
}

