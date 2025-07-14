import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:wordini/Pages/home.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:wordini/Pages/quizzes.dart';
import 'package:wordini/encryption_controller.dart';
import 'package:wordini/notification_controller.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); 
  // Load gpt api key from .env file
  await dotenv.load();
  OpenAI.apiKey = dotenv.env['GPT_API_KEY'] ?? ''; 
  // Initialize the encryption service
  await EncryptionService.instance.initialize();

  // Ensure Hive is initialized
  await Hive.initFlutter(); // Initializes Hive using path_provider
  await Hive.openBox('myBox'); // Open a box

  // intiialize notificaiton stuff
  initializeNotifications();
  // Initialize timezone database
  tz.initializeTimeZones();

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


  