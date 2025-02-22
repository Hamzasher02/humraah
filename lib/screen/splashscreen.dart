import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../admin/mainscreen.dart'; // Admin Screen

import 'guestscreen.dart';
import 'home.dart'; // Guest Screen for new users

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  void _checkUserStatus() async {
    await Future.delayed(const Duration(seconds: 3)); // Splash Delay
    User? user = _auth.currentUser;

    if (user != null) {
      try {
        // Fetch user role from Firestore
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists && userDoc.data() != null) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;

          if (userData.containsKey('role')) {
            String role = userData['role'];

            if (role == 'admin') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => MainScreen(),
                ), // Admin Panel
              );
              return;
            } else if (role == 'user') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => BottomBarScreen(),
                ), // User Panel
              );
              return;
            }
          }
        }
      } catch (e) {
        print("Error fetching user role: $e");
      }
    }

    // If no user is logged in or role is undefined, navigate to GuestScreen (Login)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => WatchScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logoup.jpeg', width: 200),
            const SizedBox(height: 20),
            const Text(
              "Welcome to Humraah",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
