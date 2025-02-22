import 'dart:async';
import 'package:flutter/material.dart';

import 'screen/auth/login.dart';

class Utils {
  // Static method to handle splash screen navigation
  static void navigateAfterSplash(BuildContext context, Widget destination,
      {int durationInSeconds = 3}) {
    Timer(Duration(seconds: durationInSeconds), () {
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LoginScreen(),
          ));
    });
  }
}
