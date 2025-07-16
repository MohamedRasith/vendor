import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _totalCount = TextEditingController();
  bool isLoad = false;

  File? _imageFile;
  Uint8List? _webImage; // For Flutter Web
  final ImagePicker _picker = ImagePicker();
  List<String> selectedColors = [];
  final List<String> colors = ['Red', 'Blue', 'Green', 'Black', 'White'];
  User? user = FirebaseAuth.instance.currentUser;

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      if (kIsWeb) {
        // Web: Read image as bytes
        _webImage = await pickedFile.readAsBytes();
      } else {
        // Mobile: Use File
        _imageFile = File(pickedFile.path);
      }
      setState(() {});
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null && _webImage == null) return null;

    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference storageRef = FirebaseStorage.instance.ref().child('product_images/$fileName.jpg');

    UploadTask uploadTask;

    if (kIsWeb) {
      uploadTask = storageRef.putData(_webImage!, SettableMetadata(contentType: 'image/jpeg'));
    } else {
      uploadTask = storageRef.putFile(_imageFile!);
    }

    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> _saveProduct() async {
    setState(() {
      isLoad = true;
    });
    String? imageUrl = await _uploadImage();
    if (imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Image upload failed")));
      return;
    }

    User? user = FirebaseAuth.instance.currentUser; // Get logged-in user
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("User not logged in")));
      return;
    }

    String userEmail = user.email ?? ""; // Get user email
    String userName = "Anonymous"; // Default name

    try {
      // 🔹 Query Firestore to find the user document with the matching email
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users') // Adjust collection name if different
          .where('email', isEqualTo: userEmail)
          .limit(1) // Get only one matching document
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        var userData = userSnapshot.docs.first.data() as Map<String, dynamic>;
        userName = userData['fullName'] ?? "Anonymous"; // Fetch fullName
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }

    await FirebaseFirestore.instance.collection('products').add({
      'id' : DateTime.now().millisecondsSinceEpoch.toString(),
      'name': _nameController.text,
      'description': _descriptionController.text,
      'price': double.tryParse(_priceController.text) ?? 0.0,
      'discount': double.tryParse(_discountController.text) ?? 0.0,
      'totalCount' : double.tryParse(_totalCount.text) ?? 0.0,
      'colors': selectedColors,
      'imageUrl': imageUrl,
      'vendorName': userName,
      'timestamp': FieldValue.serverTimestamp(),
    });
    setState(() {
      isLoad = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Product Added Successfully")));
    Navigator.pop(context);
  }

  Widget _buildImagePreview() {
    if (kIsWeb) {
      return _webImage == null
          ? Container(height: 150, width: 150, color: Colors.grey[300], child: Icon(Icons.add_a_photo_rounded))
          : Image.memory(_webImage!, height: 150);
    } else {
      return _imageFile == null
          ? Container(height: 150, width: 150, color: Colors.grey[300], child: Icon(Icons.add_a_photo_rounded))
          : Image.file(_imageFile!, height: 150);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Product")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: _buildImagePreview(),
            ),
            TextField(controller: _nameController, decoration: InputDecoration(labelText: "Product Name")),
            TextField(controller: _descriptionController, decoration: InputDecoration(labelText: "Description")),
            TextField(controller: _priceController, decoration: InputDecoration(labelText: "Price"), keyboardType: TextInputType.number),
            TextField(controller: _discountController, decoration: InputDecoration(labelText: "Discount"), keyboardType: TextInputType.number),
            TextField(controller: _totalCount, decoration: InputDecoration(labelText: "In Stock"), keyboardType: TextInputType.number),
            Wrap(
              children: colors.map((color) {
                return CheckboxListTile(
                  title: Text(color),
                  value: selectedColors.contains(color),
                  onChanged: (selected) {
                    setState(() {
                      selected! ? selectedColors.add(color) : selectedColors.remove(color);
                    });
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            SizedBox(
              width: 300,
              child: ElevatedButton(
                onPressed: _saveProduct,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade800),
                child: isLoad?
                Center(child: SpinKitThreeBounce(
                  color: Colors.white,
                  size: 30.0,
                ),):
                Text('Save Product', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
