import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vendor/Pages/dashboard.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  Uint8List? _profileImageBytes;
  Uint8List? _emiratesIdFrontBytes;
  Uint8List? _emiratesIdBackBytes;

  File? _profileImage;
  File? _emiratesIdFront;
  File? _emiratesIdBack;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<dynamic> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      if (kIsWeb) {
        return await pickedFile.readAsBytes(); // Uint8List for web
      } else {
        return File(pickedFile.path);
      }
    }
    return null;
  }

  Future<String> _uploadFile(dynamic file, String path) async {
    Reference storageRef = FirebaseStorage.instance.ref().child(path);
    UploadTask uploadTask;

    if (kIsWeb) {
      uploadTask = storageRef.putData(file as Uint8List);
    } else {
      uploadTask = storageRef.putFile(file as File);
    }

    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> _registerUser() async {
    if (_formKey.currentState!.validate() &&
        (_profileImage != null || _profileImageBytes != null) &&
        (_emiratesIdFront != null || _emiratesIdFrontBytes != null) &&
        (_emiratesIdBack != null || _emiratesIdBackBytes != null)) {
      setState(() => _isLoading = true);
      try {
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        String profileUrl = await _uploadFile(kIsWeb ? _profileImageBytes : _profileImage!, 'profiles/${userCredential.user!.uid}.jpg');
        String emiratesIdFrontUrl = await _uploadFile(kIsWeb ? _emiratesIdFrontBytes : _emiratesIdFront!, 'emirates_id/${userCredential.user!.uid}_front.jpg');
        String emiratesIdBackUrl = await _uploadFile(kIsWeb ? _emiratesIdBackBytes : _emiratesIdBack!, 'emirates_id/${userCredential.user!.uid}_back.jpg');

        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'fullName': _fullNameController.text,
          'email': _emailController.text,
          'mobile': _mobileController.text,
          'address': _addressController.text,
          'profileImage': profileUrl,
          'emiratesIdFront': emiratesIdFrontUrl,
          'emiratesIdBack': emiratesIdBackUrl,
        });

        setState(() => _isLoading = false);
        final preference = await SharedPreferences.getInstance();
        preference.setBool("isLoggedIn", true);
        Navigator.push(context, MaterialPageRoute(builder: (context) => DashboardScreen()));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registration Successful!')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text('Register')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () async {
                      var image = await _pickImage(ImageSource.gallery);
                      setState(() {
                        if (kIsWeb) {
                          _profileImageBytes = image;
                        } else {
                          _profileImage = image;
                        }
                      });
                    },
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: kIsWeb
                          ? (_profileImageBytes != null ? MemoryImage(_profileImageBytes!) : null)
                          : (_profileImage != null ? FileImage(_profileImage!) : null),
                      child: (_profileImage == null && _profileImageBytes == null) ? Icon(Icons.add_a_photo) : null,
                    ),
                  ),
                  SizedBox(height: 10),
                  _buildTextField(_fullNameController, 'Full Name'),
                  _buildTextField(_emailController, 'Email'),
                  _buildTextField(_passwordController, 'Password', obscureText: true),
                  _buildTextField(_mobileController, 'Mobile Number'),
                  _buildTextField(_addressController, 'Address'),

                  SizedBox(height: 10),
                  _buildImagePicker("Emirates ID Front", _emiratesIdFront, _emiratesIdFrontBytes, (image) {
                    setState(() {
                      if (kIsWeb) {
                        _emiratesIdFrontBytes = image;
                      } else {
                        _emiratesIdFront = image;
                      }
                    });
                  }),

                  SizedBox(height: 10),
                  _buildImagePicker("Emirates ID Back", _emiratesIdBack, _emiratesIdBackBytes, (image) {
                    setState(() {
                      if (kIsWeb) {
                        _emiratesIdBackBytes = image;
                      } else {
                        _emiratesIdBack = image;
                      }
                    });
                  }),

                  SizedBox(height: 20),
                  SizedBox(
                    width: 300,
                    child: ElevatedButton(
                      onPressed: _registerUser,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade800),
                      child: _isLoading?
                          Center(child: SpinKitThreeBounce(
                            color: Colors.white,
                            size: 30.0,
                          ),):
                          Text('Register', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool obscureText = false}) {
    return SizedBox(
      width: 400,
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        obscureText: obscureText,
        validator: (value) => value!.isEmpty ? 'Enter $label' : null,
      ),
    );
  }

  Widget _buildImagePicker(String title, File? imageFile, Uint8List? imageBytes, Function(dynamic) onPick) {
    return SizedBox(
      width: 400,
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
            GestureDetector(
              onTap: () async {
                var image = await _pickImage(ImageSource.camera);
                onPick(image);
              },
              child: Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: kIsWeb
                    ? (imageBytes != null ? Image.memory(imageBytes, fit: BoxFit.cover) : Center(child: Icon(Icons.add_a_photo, size: 50)))
                    : (imageFile != null ? Image.file(imageFile, fit: BoxFit.cover) : Center(child: Icon(Icons.add_a_photo, size: 50))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
