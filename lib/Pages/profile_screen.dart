import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vendor/Pages/login_page.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  String? vendorName;
  String? vendorEmail;
  String? vendorMobile;
  String? vendorCity;
  bool isSignedIn = false;

  @override
  void initState() {
    super.initState();
    loadVendorInfo();
  }

  Future<void> loadVendorInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isSignedIn = prefs.getBool('isSignedIn') ?? false;
      vendorName = prefs.getString('vendorName');
      vendorEmail = prefs.getString('vendorEmail');
      vendorMobile = prefs.getString('vendorMobile');
      vendorCity = prefs.getString('vendorCity');
    });
  }

  Future<void> loginVendor(String email, String password) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('vendors')
        .where('vendorName', isEqualTo: email)
        .where('contactPersonEmail', isEqualTo: password)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final vendor = snapshot.docs.first.data();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isSignedIn', true);
      await prefs.setString('vendorName', vendor['vendorName']);
      await prefs.setString('vendorEmail', vendor['contactPersonEmail']);
      await prefs.setString('vendorMobile', vendor['contactPersonNumber']);
      await prefs.setString('vendorCity', vendor['city']);
      await loadVendorInfo();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid vendor credentials')),
      );
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    setState(() {
      isSignedIn = false;
      vendorName = null;
      vendorEmail = null;
    });
    Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen()));
  }

  void showLoginDialog() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Vendor Login"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              loginVendor(emailController.text.trim(), passwordController.text.trim());
            },
            child: const Text("Login"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome, $vendorName', style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 8),
          Text('Email: $vendorEmail'),
          const SizedBox(height: 8),
          Text('Mobile: $vendorMobile'),
          const SizedBox(height: 8),
          Text('City: $vendorCity'),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: logout,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.logout),
            label: const Text("Logout"),
          ),
        ],
      )
    );
  }
}