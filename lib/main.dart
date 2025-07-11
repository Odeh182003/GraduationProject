import 'package:bzu_leads/pages/login_page.dart';
import 'package:bzu_leads/services/ApiConfig.dart';
//import 'package:bzu_leads/themes/light_theme.dart';
import 'package:bzu_leads/themes/theme_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bzu_leads/pages/academicdashboard.dart';
import 'package:bzu_leads/pages/officialsdashboard.dart';
import 'package:bzu_leads/pages/studentDashboard.dart';

import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConfig.loadBaseUrl();
 // NotiService().initNotification(); // Initialize notifications
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: "AIzaSyCQidIoZweVFao_8LmQBOQo_rviZ8Uq5BE",
          authDomain: "chattingapp-24c9a.firebaseapp.com",
          projectId: "chattingapp-24c9a",
          storageBucket: "chattingapp-24c9a.appspot.com",  
          messagingSenderId: "25606049528",
          appId: "1:25606049528:web:0d23c82c5c90fa12be750d",
          measurementId: "G-4M8364G3Y5",
        ),
      );
    } else {
      await Firebase.initializeApp();
    }

    runApp(
      ChangeNotifierProvider(
        create: (context) => ThemeProvider(),
        child: MyApp(),
      ),
    );
  } catch (e) {
    if (kDebugMode) {
      print("Firebase initialization error: $e");
    }
  }
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context); // Get the theme

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BZU_Leads',
      theme: themeProvider.themeData, // Use dynamic theme
      initialRoute: "/",
      routes: {
        "/": (context) => const Login(),
        "/student_dashboard": (context) => PublicPosts(),
        "/academic_dashboard": (context) => Academicdashboard(),
        "/official_dashboard": (context) => Officialsdashboard(),
      },
    );
  }
}