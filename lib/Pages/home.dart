// import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:vocab_app/Pages/add_word.dart';
import 'package:vocab_app/Pages/quizzes.dart';
import 'package:vocab_app/Pages/settings.dart';
import 'package:vocab_app/Pages/word_list.dart';
import 'package:vocab_app/file_handling.dart';
import 'package:fl_chart/fl_chart.dart';

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
      body: Stack(
        children: [
          Positioned(
            right: 0,
            child: IconButton(
              padding: EdgeInsets.all(20),
              onPressed: (){
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsPage())
                );
              }, 
              icon: Icon(Icons.settings)
            )
          ),
          _pages[_currentIndex],
        ],
      ),
    );
  }
}

class HomePageContent extends StatefulWidget {
  const HomePageContent({super.key});
  @override
  // ignore: library_private_types_in_public_api
  _HomePageContentState createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent> {
  @override
  void initState() {
    super.initState();
    fetchInputData();
  }
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WordGameStatsScreen(),
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
    );
  }
  
  void fetchInputData() async {
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

    debugPrint('Words guessed: $wordsGuessed');
    debugPrint('Speech types guessed: $speechTypesGuessed');
    debugPrint('Total guesses: $totalGuesses');
    debugPrint('Average times guessed: $averageTimesGuessed');
    debugPrint('Word guesses: $wordGuesses');
  }

}

class WordGameStatsApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Word Game Stats',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: WordGameStatsScreen(),
    );
  }
}

class WordGameStatsScreen extends StatefulWidget {
  @override
  _WordGameStatsScreenState createState() => _WordGameStatsScreenState();
}

class _WordGameStatsScreenState extends State<WordGameStatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Sample data - replace with your actual data
  final GameStats gameStats = GameStats(
    wordsGuessed: 45,
    speechTypesGuessed: 8,
    totalGuesses: 180,
    totalSkips: 12,
    correctGuesses: 45,
    wordGuesses: {
      "apple": 4,
      "beautiful": 7,
      "quickly": 3,
      "house": 2,
      "running": 5,
      "elephant": 8,
      "mysterious": 9,
      "jump": 1,
      "incredible": 6,
      "computer": 3,
      "happiness": 4,
      "whisper": 2,
      "adventure": 5,
      "brilliant": 7,
      "ocean": 2,
    },
  );

  final Map<String, WordInfo> wordCategories = {
    "apple": WordInfo(type: "noun", length: 5),
    "beautiful": WordInfo(type: "adjective", length: 9),
    "quickly": WordInfo(type: "adverb", length: 7),
    "house": WordInfo(type: "noun", length: 5),
    "running": WordInfo(type: "verb", length: 7),
    "elephant": WordInfo(type: "noun", length: 8),
    "mysterious": WordInfo(type: "adjective", length: 10),
    "jump": WordInfo(type: "verb", length: 4),
    "incredible": WordInfo(type: "adjective", length: 10),
    "computer": WordInfo(type: "noun", length: 8),
    "happiness": WordInfo(type: "noun", length: 9),
    "whisper": WordInfo(type: "verb", length: 7),
    "adventure": WordInfo(type: "noun", length: 9),
    "brilliant": WordInfo(type: "adjective", length: 9),
    "ocean": WordInfo(type: "noun", length: 5),
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  DerivedStats get derivedStats {
    final totalWordGuesses = gameStats.wordGuesses.values.fold(0, (sum, count) => sum + count);
    final averageGuesses = totalWordGuesses / gameStats.wordGuesses.length;
    
    final mostGuessedEntry = gameStats.wordGuesses.entries
        .reduce((a, b) => a.value > b.value ? a : b);
    
    final successRate = (gameStats.correctGuesses / gameStats.totalGuesses) * 100;
    final skipRate = (gameStats.totalSkips / (gameStats.totalGuesses + gameStats.totalSkips)) * 100;

    return DerivedStats(
      totalWordGuesses: totalWordGuesses,
      averageGuesses: averageGuesses,
      mostGuessedWord: mostGuessedEntry.key,
      mostGuessedCount: mostGuessedEntry.value,
      successRate: successRate,
      skipRate: skipRate,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 30, 30, 30)
              // gradient: LinearGradient(
              //   colors: [Colors.blue.shade600, Colors.purple.shade600],
              //   begin: Alignment.centerLeft,
              //   end: Alignment.centerRight,
              // ),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      'The Vocab Lab',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Track your progress',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade100,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Tab Bar
          Container(
            color: Color.fromARGB(255, 30, 30, 30),
            child: TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: 'Overview'),
                Tab(text: 'Charts'),
                Tab(text: 'Words'),
              ],
              labelColor: Colors.blue.shade600,
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: Colors.blue.shade600,
              dividerColor: Colors.grey.shade600,
            ),
          ),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildChartsTab(),
                _buildWordsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final stats = derivedStats;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Key Stats Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard('${gameStats.wordsGuessed}', 'Words Guessed', Colors.blue, '📝'),
              _buildStatCard('${gameStats.correctGuesses}', 'Correct', Colors.green, '✅'),
              _buildStatCard('${stats.successRate.toStringAsFixed(1)}%', 'Success Rate', Colors.purple, '🎯'),
              _buildStatCard(stats.averageGuesses.toStringAsFixed(1), 'Avg. Guesses', Colors.orange, '📊'),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Most Challenging Word Card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade400, Colors.red.shade500],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  'Most Challenging Word',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  stats.mostGuessedWord.toUpperCase(),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Guessed ${stats.mostGuessedCount} times',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${wordCategories[stats.mostGuessedWord]?.type} • ${wordCategories[stats.mostGuessedWord]?.length} letters',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 16),
          
          // Progress Bars
          _buildProgressCard(stats),
          
          SizedBox(height: 16),
          
          // Quick Stats
          Row(
            children: [
              Expanded(
                child: _buildQuickStatCard('${gameStats.speechTypesGuessed}', 'Speech Types', const Color.fromARGB(255, 198, 50, 224)),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildQuickStatCard('${gameStats.wordGuesses.length}', 'Unique Words', const Color.fromARGB(255, 76, 98, 219)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Bar Chart
          _buildChartCard(
            'Most Guessed Words',
            Container(
              height: 250,
              child: _buildBarChart(),
            ),
          ),
          
          SizedBox(height: 16),
          
          // Pie Chart
          _buildChartCard(
            'Word Types',
            Container(
              height: 200,
              child: _buildPieChart(),
            ),
          ),
          
          SizedBox(height: 16),
          
          // Quick Stats
          _buildChartCard(
            'Quick Stats',
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${gameStats.totalGuesses}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade600,
                          ),
                        ),
                        Text(
                          'Total Guesses',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${gameStats.totalSkips}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade600,
                          ),
                        ),
                        Text(
                          'Total Skips',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordsTab() {
    final sortedWords = gameStats.wordGuesses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'All Words (${gameStats.wordGuesses.length})',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: sortedWords.length,
            itemBuilder: (context, index) {
              final entry = sortedWords[index];
              final wordInfo = wordCategories[entry.key];
              
              return Container(
                margin: EdgeInsets.only(bottom: 8),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 30, 30, 30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${wordInfo?.type ?? 'unknown'} • ${wordInfo?.length ?? entry.key.length} letters',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100.withAlpha(240),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${entry.value}×',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, Color color, String emoji) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 30, 30, 30),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
          Text(
            emoji,
            style: TextStyle(fontSize: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(DerivedStats stats) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 30, 30, 30),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),
          _buildProgressBar('Success Rate', stats.successRate, Colors.green),
          SizedBox(height: 16),
          _buildProgressBar('Skip Rate', stats.skipRate, Colors.red),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, double percentage, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
        ),
      ],
    );
  }

  Widget _buildQuickStatCard(String value, String label, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 30, 30, 30),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade200,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(String title, Widget chart) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 30, 30, 30),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),
          chart,
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    final topWords = gameStats.wordGuesses.entries
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value));
    final chartData = topWords.take(8).toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: chartData.first.value.toDouble() + 1,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value.toInt() < chartData.length) {
                  return Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      chartData[value.toInt()].key,
                      style: TextStyle(fontSize: 10),
                    ),
                  );
                }
                return Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: chartData.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.value.toDouble(),
                color: Colors.blue.shade600,
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPieChart() {
    final speechTypes = <String, int>{};
    gameStats.wordGuesses.forEach((word, count) {
      final type = wordCategories[word]?.type ?? 'unknown';
      speechTypes[type] = (speechTypes[type] ?? 0) + count;
    });

    final colors = [
      Colors.blue.shade600,
      Colors.green.shade600,
      Colors.orange.shade600,
      Colors.red.shade600,
      Colors.purple.shade600,
    ];

    return PieChart(
      PieChartData(
        sections: speechTypes.entries.map((entry) {
          final index = speechTypes.keys.toList().indexOf(entry.key);
          return PieChartSectionData(
            color: colors[index % colors.length],
            value: entry.value.toDouble(),
            title: '${entry.key}\n${entry.value}',
            radius: 80,
            titleStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList(),
      ),
    );
  }
}

// Data Models
class GameStats {
  final int wordsGuessed;
  final int speechTypesGuessed;
  final int totalGuesses;
  final int totalSkips;
  final int correctGuesses;
  final Map<String, int> wordGuesses;

  GameStats({
    required this.wordsGuessed,
    required this.speechTypesGuessed,
    required this.totalGuesses,
    required this.totalSkips,
    required this.correctGuesses,
    required this.wordGuesses,
  });
}

class WordInfo {
  final String type;
  final int length;

  WordInfo({required this.type, required this.length});
}

class DerivedStats {
  final int totalWordGuesses;
  final double averageGuesses;
  final String mostGuessedWord;
  final int mostGuessedCount;
  final double successRate;
  final double skipRate;

  DerivedStats({
    required this.totalWordGuesses,
    required this.averageGuesses,
    required this.mostGuessedWord,
    required this.mostGuessedCount,
    required this.successRate,
    required this.skipRate,
  });
}