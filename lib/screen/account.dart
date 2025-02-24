import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  /// Function to pick an image from the given source.
  Future<File?> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  /// Updates the current logged-in user's profile in Firestore.
  Future<void> _updateUserProfile(
    String profileName,
    File? profilePhoto,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    String? profileImageUrl;
    if (profilePhoto != null) {
      // Upload the profile photo to Firebase Storage.
      final storageRef = FirebaseStorage.instance.ref().child(
        'profile_images/${currentUser.uid}.png',
      );
      await storageRef.putFile(profilePhoto);
      profileImageUrl = await storageRef.getDownloadURL();
    }

    // Update the Firestore document in "users" collection.
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .update({
          'profileName': profileName,
          if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
        });
  }

  /// Shows a dialog allowing the user to add a profile photo (from camera or gallery) and name.
  void _showCreateProfileDialog(BuildContext context) {
    String profileName = "";
    File? profilePhoto;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Using StatefulBuilder to update dialog state.
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.black,
              title: const Text(
                "Create Profile",
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tappable avatar to pick image.
                  GestureDetector(
                    onTap: () {
                      // Show bottom sheet to choose between camera and gallery.
                      showModalBottomSheet(
                        context: context,
                        builder: (context) {
                          return SafeArea(
                            child: Wrap(
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.photo_library),
                                  title: const Text('Gallery'),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    final image = await _pickImage(
                                      ImageSource.gallery,
                                    );
                                    if (image != null) {
                                      setState(() {
                                        profilePhoto = image;
                                      });
                                    }
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.camera_alt),
                                  title: const Text('Camera'),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    final image = await _pickImage(
                                      ImageSource.camera,
                                    );
                                    if (image != null) {
                                      setState(() {
                                        profilePhoto = image;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey.shade800,
                      backgroundImage:
                          profilePhoto != null
                              ? FileImage(profilePhoto!)
                              : null,
                      child:
                          profilePhoto == null
                              ? const Icon(
                                Icons.camera_alt,
                                size: 40,
                                color: Colors.white,
                              )
                              : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // TextField for entering profile name.
                  TextField(
                    onChanged: (value) {
                      profileName = value;
                    },
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "Enter profile name",
                      hintStyle: TextStyle(color: Colors.grey),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (profileName.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please enter a profile name"),
                        ),
                      );
                      return;
                    }
                    // Update current user's profile with the new details.
                    await _updateUserProfile(profileName, profilePhoto);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Profile '$profileName' updated")),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text("Create"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sample profiles for existing accounts.
    final profiles = [
      {'name': 'UIUXDIVYANSHU', 'image': 'assets/Profile-ring.png'},
      {'name': 'MRPANTHER', 'image': 'assets/Ellipse 19.png'},
      {'name': 'INAVITABLE', 'image': 'assets/Ellipse 13.png'},
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Account",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          const Text(
            "Who's Watching?",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),
          // First profile (centered)
          Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    backgroundImage: const AssetImage(
                      "assets/Profile-ring.png",
                    ),
                    radius: 50,
                  ),
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color.fromARGB(62, 214, 148, 144),
                        width: 2,
                      ),
                    ),
                  ),
                ],
              ),
              const Text("UIUXDIVYANSHU"),
            ],
          ),
          const SizedBox(height: 10),
          // Row for second and third profiles
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          backgroundImage: const AssetImage(
                            "assets/Ellipse 19.png",
                          ),
                          radius: 50,
                        ),
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color.fromARGB(62, 214, 148, 144),
                              width: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Text("MRPANTHER"),
                  ],
                ),
                const SizedBox(width: 20),
                Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          backgroundImage: const AssetImage(
                            "assets/Ellipse 13.png",
                          ),
                          radius: 50,
                        ),
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color.fromARGB(62, 214, 148, 144),
                              width: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Text("INAVITABLE"),
                  ],
                ),
              ],
            ),
          ),
          // "Create Profile" button
          const SizedBox(height: 20),
          InkWell(
            onTap: () {
              _showCreateProfileDialog(context);
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey.shade800,
                  child: const Icon(Icons.add, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Create Profile",
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
