import 'package:flutter/material.dart';
import 'package:vendor/Pages/login_page.dart';
import 'package:vendor/Pages/profile_screen.dart';
import 'package:vendor/Pages/register_page.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo at the top
            Image.asset("assets/images/logo.png", height: 100),
            SizedBox(height: 50),

            // Login Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: MaterialButton(
                onPressed: () {
                  // Navigate to Login Page
                  Navigator.push(context, MaterialPageRoute(builder: (context) => MyProfileScreen()));
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                  side: BorderSide(color: Colors.purple.shade800, width: 2),
                ),
                padding: EdgeInsets.symmetric(vertical: 15),
                minWidth: 200,
                color: Colors.purple.shade800,
                child: Text(
                  'Login',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),

            SizedBox(height: 20),

            // Sign Up Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: MaterialButton(
                onPressed: () {
                  // Navigate to SignUp Page
                  Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterPage()));
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                  side: BorderSide(color: Colors.purple.shade800, width: 2),
                ),
                padding: EdgeInsets.symmetric(vertical: 15),
                minWidth: 200,
                color: Colors.purple.shade800,
                child: Text(
                  'Sign Up',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
