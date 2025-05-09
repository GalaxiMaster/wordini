import 'package:flutter/material.dart';
import 'package:vocab_app/Pages/home.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Colors.blue,
        )
      ),
      debugShowCheckedModeBanner: false,
      home: HomePage()
    );
  }
}
