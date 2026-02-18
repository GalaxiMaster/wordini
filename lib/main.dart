import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wordini/Pages/home.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:wordini/Pages/quizzes.dart';
import 'package:wordini/Providers/otherproviders.dart';
import 'package:wordini/encryption_controller.dart';
import 'package:wordini/file_handling.dart';
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
  // Initialize the encryption service
  await EncryptionService.instance.initialize();

  // Ensure Hive is initialized
  await Hive.initFlutter(); // Initializes Hive using path_provider
  await Hive.openBox('userData'); // Open a box
  await Hive.openBox('permissions'); // Open a box

  // intiialize notificaiton stuff
  initializeNotifications();
  // Initialize timezone database
  tz.initializeTimeZones();

  getUserPermissions();
  
  runApp(const ProviderScope(child: MainApp()));
}


class MainApp extends ConsumerWidget {
  const MainApp({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.dark(
          primary: ref.watch(themeProvider),
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