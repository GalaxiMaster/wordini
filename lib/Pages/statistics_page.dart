// import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class WordGameStatsScreen extends StatefulWidget {
  const WordGameStatsScreen({super.key});

  @override
  WordGameStatsScreenState createState() => WordGameStatsScreenState();
}

class WordGameStatsScreenState extends State<WordGameStatsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late GameStats gameStats;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // gameStats = widget.gameData; TODO use providers
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  DerivedStats get derivedStats {
    final totalWordGuesses = gameStats.wordGuesses.values.fold(0, (sum, count) => sum + count);
    final averageGuesses = gameStats.wordGuesses.isNotEmpty
        ? totalWordGuesses / gameStats.wordGuesses.length
        : 0.0;
    final MapEntry? mostGuessedEntry;
    if (gameStats.wordGuesses.isNotEmpty){
      mostGuessedEntry = gameStats.wordGuesses.entries
          .reduce((a, b) => a.value > b.value ? a : b);
    } else{
      mostGuessedEntry = null;
    }

    final successRate = gameStats.totalGuesses > 0
      ? (gameStats.correctGuesses / gameStats.totalGuesses) * 100
      : 0.0;

    final skipRate = (gameStats.totalGuesses + gameStats.totalSkips) > 0
      ? (gameStats.totalSkips / (gameStats.totalGuesses + gameStats.totalSkips)) * 100
      : 0.0;
    return DerivedStats(
      totalWordGuesses: totalWordGuesses,
      averageGuesses: averageGuesses,
      mostGuessedWord: mostGuessedEntry?.key,
      mostGuessedCount: mostGuessedEntry?.value,
      successRate: successRate,
      skipRate: skipRate,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Tab Bar
          Container(
            width: double.infinity,
            color: Color.fromARGB(255, 30, 30, 30),
            height: 82.5, // Set an explicit height
            child: Padding(
              padding: const EdgeInsets.only(top: 30),
              child: Stack(
                children: [      // Full-width TabBar
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.center,
                      child: TabBar(
                        controller: _tabController,
                        tabs: const [
                          Tab(text: 'Overview'),
                          Tab(text: 'Charts'),
                        ],
                        labelColor: Colors.blue,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Colors.blue,
                        dividerColor: Colors.grey,
                      ),
                    ),
                  ),
                  // IconButton overlay
                  Positioned(
                    left: 5,
                    top: 0,
                    bottom: 0,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildChartsTab(),
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
      padding: EdgeInsets.symmetric(horizontal: 16),
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
              _buildStatCard('${gameStats.wordsAdded}', 'Words Added', Colors.purple, '+'),
              _buildStatCard(stats.averageGuesses.toStringAsFixed(1), 'Avg. Guesses', Colors.orange, '📊'),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Most Challenging Word Card
          // Container(
          //   width: double.infinity,
          //   decoration: BoxDecoration(
          //     gradient: LinearGradient(
          //       colors: [Colors.orange.shade400, Colors.red.shade500],
          //       begin: Alignment.centerLeft,
          //       end: Alignment.centerRight,
          //     ),
          //     borderRadius: BorderRadius.circular(16),
          //   ),
          //   padding: EdgeInsets.all(24),
          //   child: Column(
          //     children: [
          //       Text(
          //         'Most Challenging Word',
          //         style: TextStyle(
          //           fontSize: 14,
          //           color: Colors.white.withOpacity(0.9),
          //         ),
          //       ),
          //       SizedBox(height: 8),
          //       Text(
          //         stats.mostGuessedWord.toUpperCase(),
          //         style: TextStyle(
          //           fontSize: 28,
          //           fontWeight: FontWeight.bold,
          //           color: Colors.white,
          //         ),
          //       ),
          //       SizedBox(height: 8),
          //       Text(
          //         'Guessed ${stats.mostGuessedCount} times',
          //         style: TextStyle(
          //           fontSize: 16,
          //           color: Colors.white,
          //         ),
          //       ),
          //       SizedBox(height: 4),
          //       Text(
          //         '${wordCategories[stats.mostGuessedWord]?.type} • ${wordCategories[stats.mostGuessedWord]?.length} letters',
          //         style: TextStyle(
          //           fontSize: 12,
          //           color: Colors.white.withOpacity(0.8),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          
          // SizedBox(height: 16),
          
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
          // Pie Chart
          // _buildChartCard(
          //   'Word Types',
          //   SizedBox(
          //     height: 200,
          //     child: _buildPieChart(),
          //   ),
          // ),
          
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
                      color: Colors.blue.shade100,
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
                      color: Colors.red.shade100,
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

  Widget _buildStatCard(String value, String label, Color color, String emoji) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 30, 30, 30),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 66, 66, 66).withOpacity(0.1),
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
            color: const Color.fromARGB(255, 66, 66, 66).withOpacity(0.1),
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
          backgroundColor: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(10),
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
            color: const Color.fromARGB(255, 66, 66, 66).withOpacity(0.1),
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
            color: const Color.fromARGB(255, 66, 66, 66).withOpacity(0.1),
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

  // Widget _buildPieChart() {
  //   final speechTypes = <String, int>{};
  //   gameStats.wordGuesses.forEach((word, count) {
  //     final type = wordCategories[word]?.type ?? 'unknown';
  //     speechTypes[type] = (speechTypes[type] ?? 0) + count;
  //   });

  //   final colors = [
  //     Colors.blue.shade600,
  //     Colors.green.shade600,
  //     Colors.orange.shade600,
  //     Colors.red.shade600,
  //     Colors.purple.shade600,
  //   ];

  //   return PieChart(
  //     PieChartData(
  //       sections: speechTypes.entries.map((entry) {
  //         final index = speechTypes.keys.toList().indexOf(entry.key);
  //         return PieChartSectionData(
  //           color: colors[index % colors.length],
  //           value: entry.value.toDouble(),
  //           title: '${entry.key}\n${entry.value}',
  //           radius: 80,
  //           titleStyle: TextStyle(
  //             fontSize: 12,
  //             fontWeight: FontWeight.bold,
  //             color: Colors.white,
  //           ),
  //         );
  //       }).toList(),
  //     ),
  //   );
  // }
}

// Data Models
class GameStats {
  final int wordsGuessed;
  final int speechTypesGuessed;
  final int totalGuesses;
  final int totalSkips;
  final int correctGuesses;
  final Map<String, int> wordGuesses;
  final int wordsAdded;

  GameStats({
    required this.wordsGuessed,
    required this.speechTypesGuessed,
    required this.totalGuesses,
    required this.totalSkips,
    required this.correctGuesses,
    required this.wordGuesses,
    required this.wordsAdded, 
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
  final String? mostGuessedWord;
  final int? mostGuessedCount;
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