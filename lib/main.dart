import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'screen/splashscreen.dart';

// Import generated file

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Firebase Demo',
      theme: ThemeData.dark(),
      home: SplashScreen(),
    );
  }
}
