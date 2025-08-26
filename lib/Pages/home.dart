// import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wordini/Pages/add_word.dart';
import 'package:wordini/Pages/quizzes.dart';
import 'package:wordini/Pages/settings.dart';
import 'package:wordini/Pages/statistics_page.dart';
import 'package:wordini/Pages/word_list.dart';
import 'package:wordini/Providers/goal_providers.dart';
import 'package:wordini/Providers/otherproviders.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:wordini/widgets.dart';
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends ConsumerState<HomePage> {
  int _currentIndex = 1;
  final List<Widget> _pages = [
    WordList(),
    HomePageContent(),
    Quizzes(),
  ];
  @override
  void initState() {
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(futureInputDataProvider); // Todo adjust to wait for all needed data

    return asyncData.when(
      data: (_) {
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
      },
      error: (err, stack) => Scaffold(
        body: Center(child: Text('Error loading data: $err')),
      ),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class HomePageContent extends ConsumerStatefulWidget {
  const HomePageContent({super.key});
  @override
  HomePageContentState createState() => HomePageContentState();
}

class HomePageContentState extends ConsumerState<HomePageContent> {
  @override
  void initState() {
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    final Map statisticsData = ref.watch(statisticsDataProvider);
    final Map settingsData = ref.watch(settingsProvider);
    final int wordsThisWeek = ref.watch(wordsThisWeekDataProvider);
    return Scaffold(
        appBar: AppBar(
          title: Center(child: Text('Wordini')),
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
                  MaterialPageRoute(builder: (context) => WordGameStatsScreen(gameData: inputToGameStats(ref.read(statisticsDataProvider), ref.read(wordDataProvider)),))
                );
              }, 
              icon: Icon(Icons.bar_chart)
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(inputDataProvider);
            ref.invalidate(wordDataFutureProvider);

            debugPrint('Refreshing data...');
          },
          child: SizedBox(
            height: double.infinity,
            child: Stack(
              children: [
                SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(25),
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
                        GestureDetector(
                          onTap: () async {
                            final int? value = await showModalBottomSheet(
                              context: context,
                              builder: (context) {
                                return const GoalOptions(goal: 'wordsThisWeek');
                              },
                            );
                            if (value != null) {
                              ref.read(settingsProvider.notifier).updateValue('wordsThisWeek', value);     
                              // TODO perminence                     
                            }
                          },
                          child: Container(
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
                                    '$wordsThisWeek / ${settingsData['wordsThisWeek'] ?? 20}',
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
                                    value: wordsThisWeek / (settingsData['wordsThisWeek'] ?? 20),
                                    backgroundColor: Colors.grey.shade800,
                                    borderRadius: BorderRadius.circular(10),
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                                    minHeight: 12,
                                  ),
                                ],
                              ),
                            )
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'Word Testing',
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
                            GestureDetector(
                              onLongPress: () async {
                                final int? value = await showModalBottomSheet(
                                  context: context,
                                  builder: (context) {
                                    return const GoalOptions(goal: 'WT-today');
                                  },
                                );
                                if (value != null) {
                                  ref.read(settingsProvider.notifier).updateValue('WT-today', value);   
                                  // TODO permindence                       
                                }
                              },
                              child: dataGaugeChart('Today', statisticsData['guessesToday'], settingsData['WT-today'] ?? 4, context)
                            ),
                            GestureDetector(
                              onLongPress: () async{
                                final int? value = await showModalBottomSheet(
                                  context: context,
                                  builder: (context) {
                                    return const GoalOptions(goal: 'WT-thisWeek');
                                  },
                                );
                                if (value != null) {
                                  ref.read(settingsProvider.notifier).updateValue('WT-thisWeek', value);                          
                                }
                              },
                              child: dataGaugeChart('This week', statisticsData['guessesThisWeek'], settingsData['WT-thisWeek'] ?? 20, context)
                            ),
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
                                      onPressed: (){
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => Quizzes(questions: value))
                                        );
                                      },
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
        ),
      );
    }

  Padding dataGaugeChart(String title, int value, int goal, BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Color.fromARGB(255, 30, 30, 30),
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
                  letterSpacing: .5,
                ),
              ),
            ),
            SizedBox(
              width: (MediaQuery.of(context).size.width - 32 - 25 - 70) / 2,
              height: (MediaQuery.of(context).size.width - 32 - 25 - 70) / 2,
              child: SfRadialGauge(
                axes: <RadialAxis>[
                  RadialAxis(
                    minimum: 0,
                    maximum: goal.toDouble(),
                    showLabels: false,
                    showTicks: false,
                    startAngle: 135,
                    endAngle: 45,
                    axisLineStyle: AxisLineStyle(
                      thickness: 0.15,
                      thicknessUnit: GaugeSizeUnit.factor,
                      cornerStyle: CornerStyle.bothCurve,
                      color: Colors.grey.shade800,
                    ),
                    pointers: <GaugePointer>[
                      RangePointer(
                        value: value.toDouble(),
                        width: 0.15,
                        sizeUnit: GaugeSizeUnit.factor,
                        color: Colors.green,
                        cornerStyle: CornerStyle.bothCurve,
                      )
                    ],
                    annotations: <GaugeAnnotation>[
                      GaugeAnnotation(
                        angle: 90,
                        widget: RichText(
                          text: TextSpan(
                            text: '$value',
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
                      )
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

GameStats inputToGameStats(Map input, Map wordData) {
  return GameStats(
    wordsGuessed: input['wordsGuessed'], 
    speechTypesGuessed: input['speechTypesGuessed'], 
    totalGuesses: input['totalGuesses'], 
    totalSkips: input['totalSkips'], 
    correctGuesses: input['correctGuesses'], 
    wordGuesses: input['wordGuesses'], 
    wordsAdded: wordData.length
  );
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