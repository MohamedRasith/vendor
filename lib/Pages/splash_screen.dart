import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vendor/Pages/auth_page.dart';
import 'package:vendor/Pages/dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool isLoggedIn = false;
  getPrefs() async{
    final prefs = await SharedPreferences.getInstance();
    setState(() {
     isLoggedIn = prefs.getBool("isLoggedIn") ?? false;
    });
  }
  @override
  void initState() {
    super.initState();
    // Navigate to Home Screen after 3 seconds
    loadAndNavigate();
  }
  void loadAndNavigate() async {
    await getPrefs(); // wait for shared prefs to load

    Future.delayed(Duration(seconds: 3), () {
      if (isLoggedIn) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AuthPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Background color
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Image.asset("assets/images/logo.png", height: 100),
            const SizedBox(
              height: 10,
            ),
            Text("Vendor App", style: TextStyle(fontSize: 20, fontFamily: GoogleFonts.aboreto().fontFamily, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            // Loading Indicator
            SpinKitThreeBounce(
              color: Colors.purple.shade800,
              size: 30.0,
            ),
          ],
        ),
      ),
    );
  }
}
