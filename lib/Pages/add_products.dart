import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:vendor/widget/category_drop_down.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  bool isLoading = false;
  bool isImageLoading = false;
  final _formKey = GlobalKey<FormState>();
  final List<String> categories = ['Electronics', 'Fashion', 'Home', 'Books'];
  final Map<String, List<String>> subcategories = {
    'Electronics': ['Mobiles', 'Laptops', 'Cameras'],
    'Fashion': ['Men', 'Women', 'Kids'],
    'Home': ['Furniture', 'Decor', 'Kitchen'],
    'Books': ['Fiction', 'Non-fiction', 'Academic'],
  };

  String? selectedCategory;
  String? selectedSubCategory;
  final Map<String, TextEditingController> controllers = {
    'brand': TextEditingController(),
    'title': TextEditingController(),
    'barcode': TextEditingController(),
    'asin': TextEditingController(),
    'nin': TextEditingController(),
    'description': TextEditingController(),
    'category': TextEditingController(),
    'subcategory': TextEditingController(),
    'feature1': TextEditingController(),
    'feature2': TextEditingController(),
    'feature3': TextEditingController(),
    'feature4': TextEditingController(),
    'weight': TextEditingController(),
    'length': TextEditingController(),
    'width': TextEditingController(),
    'height': TextEditingController(),
    'origin': TextEditingController(),
    'hsn': TextEditingController(),
    'vendor': TextEditingController(),
    'purchasePrice': TextEditingController(),
    'rsp': TextEditingController(),
  };

  List<String> uploadedImages = [];
  List<String> imageUrls = [];
  final int maxImages = 5;
  final ImagePicker _picker = ImagePicker();
  Future<void> pickAndUploadImage() async {
    try {
      setState(() {
        isImageLoading = true;
      });
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final Uint8List bytes = await pickedFile.readAsBytes();

        final fileName = const Uuid().v4(); // Unique file name
        final storageRef = FirebaseStorage.instance.ref().child("uploads/$fileName.jpg");

        final uploadTask = await storageRef.putData(bytes);
        final downloadUrl = await uploadTask.ref.getDownloadURL();

        setState(() {
          imageUrls.add(downloadUrl);
          isImageLoading = false;
        });

        debugPrint("Uploaded image URL: $downloadUrl");
      }
    } catch (e) {
      debugPrint("Error picking/uploading image: $e");
    }
  }

  void removeImage(int index) {
    setState(() {
      imageUrls.removeAt(index);
    });
  }

  void submitProduct() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all mandatory fields")),
      );
      return;
    }

    if (uploadedImages.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("At least 2 images are required.")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    Map<String, dynamic> data = {
      'brand': controllers['brand']!.text,
      'title': controllers['title']!.text,
      'barcode': controllers['barcode']!.text,
      'asin': controllers['asin']!.text,
      'nin': controllers['nin']!.text,
      'description': controllers['description']!.text,
      'category': controllers['category']!.text,
      'subcategory': controllers['subcategory']!.text,
      'features': [
        controllers['feature1']!.text,
        controllers['feature2']!.text,
        controllers['feature3']!.text,
        controllers['feature4']!.text
      ],
      'images': uploadedImages,
      'dimensions': {
        'weightKg': controllers['weight']!.text,
        'lengthCm': controllers['length']!.text,
        'widthCm': controllers['width']!.text,
        'heightCm': controllers['height']!.text,
      },
      'origin': controllers['origin']!.text,
      'hsnCode': controllers['hsn']!.text,
      'vendor': controllers['vendor']!.text,
      'purchasePrice': double.tryParse(controllers['purchasePrice']!.text),
      'rsp': double.tryParse(controllers['rsp']!.text),
      'createdAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance.collection('products').add(data);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Product added successfully")),
    );
    Navigator.pop(context);
    setState(() {
      isLoading = false;
    });
  }

  Widget buildTextField(String label, String key,
      {bool required = false, TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 120, // fixed width for label
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: controllers[key],
              keyboardType: keyboardType,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true, // reduces height a bit
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              validator: (value) {
                if (required && (value == null || value.trim().isEmpty)) {
                  return '$label is required';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Product")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left labels
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildTextField("Brand", "brand", required: true),
                    buildTextField("Product Title", "title", required: true),
                    buildTextField("Barcode", "barcode", required: true),
                    buildTextField("ASIN", "asin"),
                    buildTextField("NIN", "nin"),
                    buildTextField("Description", "description", required: true),
                    CategoryDropdown(controller: controllers['category']!),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: selectedSubCategory,
                      decoration: const InputDecoration(
                        labelText: 'Sub Category',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      items: (subcategories[selectedCategory] ?? []).map((sub) {
                        return DropdownMenuItem<String>(
                          value: sub,
                          child: Text(sub),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedSubCategory = value;
                          controllers['subcategory']!.text = value!;
                        });
                      },
                      validator: (value) => value == null ? 'Sub Category is required' : null,
                    ),
                    buildTextField("Feature 1", "feature1", required: true),
                    buildTextField("Feature 2", "feature2", required: true),
                    buildTextField("Feature 3", "feature3", required: true),
                    buildTextField("Feature 4", "feature4", required: true),
                    buildTextField("Country of Origin", "origin"),
                    buildTextField("HSN Code", "hsn"),
                    buildTextField("Vendor", "vendor", required: true),
                    buildTextField("Purchase Price", "purchasePrice", required: true, keyboardType: TextInputType.number),
                    buildTextField("RSP", "rsp", required: true, keyboardType: TextInputType.number),
                  ],
                ),
              ),

              const SizedBox(width: 40),

              // Right inputs
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildTextField("Weight (KG)", "weight", keyboardType: TextInputType.number),
                    buildTextField("Length (CM)", "length", keyboardType: TextInputType.number),
                    buildTextField("Width (CM)", "width", keyboardType: TextInputType.number),
                    buildTextField("Height (CM)", "height", keyboardType: TextInputType.number),

                    const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    children: [
                      ...imageUrls.map((url) {
                        return Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Image.network(
                                url,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    imageUrls.remove(url);
                                  });
                                },
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),

                      if (imageUrls.length < maxImages)
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: pickAndUploadImage,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
                              child: isImageLoading?
                                  const CircularProgressIndicator()
                                  :const Center(child: Icon(Icons.add_a_photo)),
                            ),
                          ),
                        )
                    ],
                  ),
                    const SizedBox(height: 8),
                    Text("Uploaded Images: ${imageUrls.length}"),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: submitProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                      child: isLoading?
                          const Center(child: CircularProgressIndicator(color: Colors.white,),)
                          :const Text("Submit Product", style: TextStyle(color: Colors.white),),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
