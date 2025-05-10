import 'package:flutter/material.dart';
import 'package:vocab_app/file_handling.dart';
import 'package:vocab_app/word_functions.dart';

class Quizzes extends StatefulWidget {
  Quizzes({super.key});
  @override
  // ignore: library_private_types_in_public_api
  _QuizzesState createState() => _QuizzesState();
}

class _QuizzesState extends State<Quizzes> {
  late Future<Map> words;
  int _currentIndex = 0;
  Map currentWord = {};
  @override
  void initState() {
    super.initState();
    words = readData();
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
          return const Center(child: Text('Error loading data'));
        } else if (snapshot.hasData) {
          currentWord = snapshot.data![snapshot.data!.keys.elementAt(_currentIndex)];
          return Padding(
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
                    decoration: InputDecoration(
                      labelText: 'Search for a word',
                    ),
                    onSubmitted: (value) {
                      if (true){
                        // new word
                        if (_currentIndex < snapshot.data!.length -1) {
                          setState(() {
                            _currentIndex++;
                          });
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        } else {
          return const Center(child: Text('No data available'));
        }
      },
      ),
    );
  }
}