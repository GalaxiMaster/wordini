// import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:vocab_app/Pages/add_word.dart';
import 'package:vocab_app/Pages/quizzes.dart';
import 'package:vocab_app/Pages/settings.dart';
import 'package:vocab_app/Pages/statistics_page.dart';
import 'package:vocab_app/Pages/word_list.dart';
import 'package:vocab_app/file_handling.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

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
                      MaterialPageRoute(builder: (context) => WordGameStatsScreen(gameData: snapshot.data!['inputData'],))
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
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: Color.fromARGB(255, 30, 30, 30)
                          ),
                          width: double.infinity,
                          height: 100,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Words Added this week',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold
                                  ),
                                ),
                                SizedBox(
                                  height: 6,
                                ),
                                Text(
                                  '17/20',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5
                                  ),
                                ),
                                SizedBox(
                                  height: 6.5,
                                ),
                                LinearProgressIndicator(
                                  value: 17 / 20,
                                  backgroundColor: Colors.grey.shade800,
                                  borderRadius: BorderRadius.circular(10),
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                                  minHeight: 12,
                                ),
                              ],
                            ),
                          )
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            dataPieChart('Today', context),
                            dataPieChart('This week', context),
                          ],
                        )
                      ],
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

  Padding dataPieChart(title, BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Color.fromARGB(255, 30, 30, 30)
        ),
        child: Column(
          children: [
            Text(title),
            SizedBox(
              width: (MediaQuery.of(context).size.width-32-25-70)/2,
              height: (MediaQuery.of(context).size.width-32-25-70)/2,
              child: CircularPercentIndicator(
                radius: 70,
                lineWidth: 12,
                percent: 0.5, // 50/100
                startAngle: 180,
                center: RichText(
                  text: TextSpan(
                    text: '50',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    children: [
                      TextSpan(
                        text: ' / 100',
                        style: TextStyle(
                          fontWeight: FontWeight.normal,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                backgroundColor: Colors.grey.shade600,
                progressColor: Colors.green,
                circularStrokeCap: CircularStrokeCap.round,
              )
            ),
          ],
        ),
      ),
    );
  }
  
  Future<Map> fetchInputData() async {
    final Map<String, dynamic> inputData = await readData(path: 'inputs');
    final Map<String, dynamic> wordData = await readData();


    int wordsGuessed = 0;
    int speechTypesGuessed = 0;
    int totalGuesses = 0;
    int totalSkips = 0;
    int correctGuesses = 0;
    final Map<String, int> wordGuesses = {};

    for (final MapEntry<String, dynamic> word in inputData.entries) {
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
    Map output = {
      'wordData': {

      },
      'inputData': GameStats(
        wordsGuessed: wordsGuessed,
        speechTypesGuessed: speechTypesGuessed,
        totalGuesses: totalGuesses,
        totalSkips: totalSkips,
        correctGuesses: correctGuesses,
        wordGuesses: wordGuesses
      ),
    };
    return output;
  }
}

