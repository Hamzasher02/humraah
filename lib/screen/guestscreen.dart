import 'package:flutter/material.dart';

import 'auth/signup.dart';
import 'home.dart';

class WatchScreen extends StatelessWidget {
  const WatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight =
        MediaQuery.of(context).size.height; // Get screen height

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            children: [
              // Background Image with Blur at Bottom
              Stack(
                children: [
                  // Background Image
                  Container(
                    height: screenHeight / 2, // Set height to half the screen
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(
                            'assets/drama1.jpeg'), // Background image
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Bottom Blur Effect
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 80, // Adjust height of the blur effect
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color.fromARGB(
                                0, 20, 20, 20), // Fully transparent at top
                            Colors.black
                                .withOpacity(0.8), // Dark opacity at bottom
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Remaining Half with Gradient
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.black.withOpacity(0.9),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Main Content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 1), // Spacer to push content below the image
              // Logo
              Image.asset(
                'assets/logo.png', // Replace with your logo image
                height: 100,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),
              // Welcome Text
              const Text(
                'WELCOME!',
                style: TextStyle(
                  fontSize: 32,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 40),
              // Signup Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 100,
                    vertical: 15,
                  ),
                ),
                onPressed: () {
                  // Handle Signup Action
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Signup Clicked")),
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SignupScreen()),
                  );
                },
                child: const Text(
                  'Signup',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Watch As Guest Button
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 80,
                    vertical: 15,
                  ),
                ),
                onPressed: () {
                  // Handle Watch As Guest Action
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Watch as Guest Clicked")),
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const BottomBarScreen()),
                  );
                },
                child: const Text(
                  'Watch As Guest',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(flex: 1), // Spacer to balance content vertically
            ],
          ),
        ],
      ),
    );
  }
}
