import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth/login.dart';
import 'account.dart';

class ProfileScreen extends StatelessWidget {
  // A sample list of profiles (if needed for other UI parts).
  final List<Map<String, String>> profiles = [
    {'name': 'John', 'image': 'assets/profile1.png'},
    {'name': 'Emma', 'image': 'assets/profile2.png'},
    {'name': 'Mike', 'image': 'assets/profile3.png'},
    {'name': 'Sophia', 'image': 'assets/profile4.png'},
    {'name': 'Add Profile', 'image': 'assets/add_profile.png'},
  ];

  ProfileScreen({super.key});

  // Sign Out Button
  Widget _buildSignOutButton(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
      ),
      onPressed: () async {
        try {
          await FirebaseAuth.instance.signOut();
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
    // Get the current user.
    final user = FirebaseAuth.instance.currentUser;
    final isWeb = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 10.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Fetch and display the current user's profile info.
                if (user != null)
                  StreamBuilder<DocumentSnapshot>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final data =
                          snapshot.data!.data() as Map<String, dynamic>? ?? {};
                      final profileName = data['profileName'] ?? user.email;
                      final profileImageUrl =
                          data['profileImageUrl'] as String?;
                      return Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: isWeb ? 80 : 60,
                              backgroundImage:
                                  profileImageUrl != null
                                      ? NetworkImage(profileImageUrl)
                                      : const AssetImage(
                                            'assets/Profile-ring.png',
                                          )
                                          as ImageProvider,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  profileName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                  ),
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
                      );
                    },
                  )
                else
                  const Center(
                    child: Text(
                      "No user logged in",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                const SizedBox(height: 30),
                // Options List
                Expanded(
                  child: ListView(
                    children: [
                      ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AccountScreen(),
                            ),
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SupportScreen(),
                            ),
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AboutUsScreen(),
                            ),
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

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("About Us"),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: const Text(
          "About Us\n\nWe are dedicated to delivering quality content and outstanding user support. Our team is passionate about creating a seamless experience for our users.",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Support"),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: const Text(
          "Support\n\nFor any assistance, please contact our support team at support@example.com or call 1-800-123-4567. We are here to help 24/7.",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}
