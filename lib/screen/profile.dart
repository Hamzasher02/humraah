import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For Firebase Auth
import 'auth/login.dart';

class ProfileScreen extends StatelessWidget {
  // This list was in your code, but we are not changing design or logic here:
  final List<Map<String, String>> profiles = [
    {'name': 'John', 'image': 'assets/profile1.png'},
    {'name': 'Emma', 'image': 'assets/profile2.png'},
    {'name': 'Mike', 'image': 'assets/profile3.png'},
    {'name': 'Sophia', 'image': 'assets/profile4.png'},
    {'name': 'Add Profile', 'image': 'assets/add_profile.png'},
  ];

  ProfileScreen({super.key});

  // Sign Out Button (unchanged)
  Widget _buildSignOutButton(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
      ),
      onPressed: () async {
        try {
          await FirebaseAuth.instance.signOut(); // Sign out the user
          // Navigate to login screen and remove all previous routes
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => LoginScreen()),
            (Route<dynamic> route) => false,
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error signing out: ${e.toString()}")),
          );
        }
      },
      child: const Text(
        "Sign Out",
        style: TextStyle(fontSize: 18, color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get the currently logged-in user
    final user = FirebaseAuth.instance.currentUser;
    // If displayName is set, use that; otherwise fallback to email or a placeholder
    final userName =
        user?.displayName?.isNotEmpty == true
            ? user!.displayName
            : user?.email ?? 'No user found';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWeb = constraints.maxWidth > 600; // Check if web or mobile
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 10.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Avatar and Name Section (same design)
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: isWeb ? 80 : 60, // Adjust size for web
                        backgroundImage: const AssetImage(
                          'assets/Profile-ring.png',
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Show the current user's name/email
                          Text(
                            userName!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 5),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.white),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Edit Profile Clicked"),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Options List (unchanged)
                Expanded(
                  child: ListView(
                    children: [
                      ListTile(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Account Clicked")),
                          );
                        },
                        leading: const Icon(Icons.person, color: Colors.white),
                        title: const Text(
                          "Account",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                        ),
                      ),
                      const Divider(color: Colors.grey),
                      ListTile(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Support Clicked")),
                          );
                        },
                        leading: const Icon(Icons.help, color: Colors.white),
                        title: const Text(
                          "Support",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                        ),
                      ),
                      const Divider(color: Colors.grey),
                      ListTile(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("About Us Clicked")),
                          );
                        },
                        leading: const Icon(Icons.info, color: Colors.white),
                        title: const Text(
                          "About Us",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // Sign Out Button
                _buildSignOutButton(context),
              ],
            ),
          );
        },
      ),
    );
  }
}
