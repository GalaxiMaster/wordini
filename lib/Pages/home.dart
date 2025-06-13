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
          return Center(child: Text('Error loading data ${snapshot.error}'));
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
                      MaterialPageRoute(builder: (context) => WordGameStatsScreen(gameData: snapshot.data!['statistics'],))
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
                    child: SingleChildScrollView(
                      child: Column(
                        // crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Statistics',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold
                              ),
                            ),
                          ),
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
                                    '${snapshot.data!['homePage']['wordsThisWeek']} / 20',
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
                                    value: snapshot.data!['homePage']['wordsThisWeek'] / 20,
                                    backgroundColor: Colors.grey.shade800,
                                    borderRadius: BorderRadius.circular(10),
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                                    minHeight: 12,
                                  ),
                                ],
                              ),
                            )
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'Definition Checking',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              dataPieChart('Today', snapshot.data!['homePage']['guessesToday'], 4, context),
                              dataPieChart('This week', snapshot.data!['homePage']['guessesThisWeek'], 20, context),
                            ],
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              'Quizzes',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              double totalSpacing = 12 * 4; // 4 gaps between 4 chips
                              double chipWidth = (constraints.maxWidth - totalSpacing) / 4;
                              
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: Wrap(
                                  runSpacing: 5,
                                  children: List.generate(8, (index) {
                                    int value = 5 * (index + 1);
                                    return Container(
                                      width: chipWidth,
                                      margin: EdgeInsets.only(
                                        right: (index + 1) % 4 == 0 ? 0 : 12, // allow perfect margining for 4 chips per row
                                      ),
                                      child: RawChip(
                                        label: SizedBox(
                                          width: double.infinity,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 5),
                                            child: Text(
                                              value.toString(),
                                              style: TextStyle(fontSize: 16),
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                        backgroundColor: Color.fromARGB(255, 30, 30, 30),
                                        elevation: 0,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16.5),
                                          side: BorderSide(color: Colors.transparent, width: 0.1),
                                        ),
                                        visualDensity: VisualDensity.compact,
                                        pressElevation: 0,
                                      ),
                                    );
                                  }),
                                ),
                              );
                            },
                          )
                        ],
                      ),
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

  Padding dataPieChart(String title, int value, int goal, BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Color.fromARGB(255, 30, 30, 30)
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: .5
                ),
              ),
            ),
            SizedBox(
              width: (MediaQuery.of(context).size.width-32-25-70)/2,
              height: (MediaQuery.of(context).size.width-32-25-70)/2,
              child: CircularPercentIndicator(
                radius: 70,
                lineWidth: 12,
                percent: value/goal, // 50/100
                startAngle: 180,
                center: RichText(
                  text: TextSpan(
                    text: value.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    children: [
                      TextSpan(
                        text: ' / $goal',
                        style: TextStyle(
                          fontWeight: FontWeight.normal,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                backgroundColor: Colors.grey.shade800,
                progressColor: Colors.green,
                circularStrokeCap: CircularStrokeCap.round,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<Map> fetchInputData() async {
    final Map<String, dynamic> inputData = await readData(path: 'inputs');
    final int week = getWeekNumber(DateTime.now());

    int wordsGuessed = 0;
    int speechTypesGuessed = 0;
    int totalGuesses = 0;
    int totalSkips = 0;
    int correctGuesses = 0;
    final Map<String, int> wordGuesses = {};
    int guessesThisWeek = 0;
    int guessesToday = 0;

    for (final MapEntry<String, dynamic> word in inputData.entries) {
      wordsGuessed++;
      wordGuesses[word.key] = (wordGuesses[word.key] ?? 0) + 1;

      if (word.value is Map) {
        final Map speechTypes = word.value;
        for (final MapEntry speechType in speechTypes.entries) {
          speechTypesGuessed++;
          for (Map guess in speechType.value){
            if (guess['correct'] ?? false){
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
    final Map<String, dynamic> wordData = await readData();

    int wordsThisWeek = 0;
    
    for (MapEntry word in wordData.entries){
      final int wordWeek = getWeekNumber(DateTime.parse(word.value['dateAdded']));
      if (wordWeek == week){
        wordsThisWeek += 1;
      }
    }

    // int averageTimesGuessed = wordsGuessed > 0
    //     ? wordGuesses.values.reduce((a, b) => a + b) ~/ wordsGuessed
    //     : 0;
    Map output = {
      'homePage': {
        'guessesThisWeek': guessesThisWeek,
        'guessesToday': guessesToday,
        'wordsThisWeek': wordsThisWeek
      },
      'statistics': GameStats(
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
  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
  int getWeekNumber(DateTime date) {
    // Find the first day of the year
    DateTime firstDayOfYear = DateTime(date.year, 1, 1);
    
    // Find the first Monday of the year (ISO week standard)
    DateTime firstMonday = firstDayOfYear;
    while (firstMonday.weekday != DateTime.monday) {
      firstMonday = firstMonday.add(Duration(days: 1));
    }
    
    // If the date is before the first Monday, it belongs to the previous year's last week
    if (date.isBefore(firstMonday)) {
      return getWeekNumber(DateTime(date.year - 1, 12, 31));
    }
    
    // Calculate the week number
    int daysDifference = date.difference(firstMonday).inDays;
    return (daysDifference / 7).floor() + 1;
  }
}

