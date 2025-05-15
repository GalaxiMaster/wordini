import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vocab_app/Pages/home.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:vocab_app/Pages/quizzes.dart';
import 'package:vocab_app/notificationController.dart';
import 'package:hive_flutter/hive_flutter.dart';
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
void main() async{
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter(); // Initializes Hive using path_provider
  await Hive.openBox('myBox'); // Open a box

  initializeNotifications();
  // Initialize timezone database
  tz.initializeTimeZones();
  await dotenv.load();
  OpenAI.apiKey = dotenv.env['GPT_API_KEY'] ?? ''; 
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
      home: HomePage(),
      navigatorKey: navigatorKey,
      routes: {
        '/home': (context) => const HomePage(),
        '/testing': (context) => const Quizzes(),
      },
    );
  }
}


  