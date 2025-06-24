import 'dart:io';
import 'dart:typed_data';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class EditProductPage extends StatefulWidget {
  final DocumentSnapshot product;

  const EditProductPage({super.key, required this.product});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController brandController;
  late TextEditingController categoryController;
  late TextEditingController subCategoryController;
  late TextEditingController originController;
  late TextEditingController priceController;
  late TextEditingController asinController;
  late TextEditingController ninController;
  late TextEditingController vendorController;
  late TextEditingController barcodeController;
  late TextEditingController descriptionController;
  late TextEditingController feature1Controller;
  late TextEditingController feature2Controller;
  late TextEditingController feature3Controller;
  late TextEditingController feature4Controller;
  late TextEditingController purchaseController;
  late TextEditingController weightController;
  late TextEditingController heightController;
  late TextEditingController lengthController;
  late TextEditingController widthController;
  Map<String, bool> isUploadingImage = {
    'Image 1': false,
    'Image 2': false,
    'Image 3': false,
    'Image 4': false,
    'Image 5': false,
  };
  Map<String, String?> imageUrls = {};
  final CarouselController _carouselController = CarouselController();
  int _currentImageIndex = 0;
  Map<String, String?> originalImageUrls = {};


  @override
  void initState() {
    super.initState();
    final data = widget.product.data() as Map<String, dynamic>;
    for (int i = 1; i <= 5; i++) {
      final key = 'Image $i';
      final url = data[key] as String? ?? '';
      imageUrls[key] = url;
      originalImageUrls[key] = url;
    }
    brandController = TextEditingController(text: widget.product['Brand'] ?? '');
    categoryController = TextEditingController(text: widget.product['Category'] ?? '');
    subCategoryController = TextEditingController(text: widget.product['Sub Category'] ?? '');
    originController = TextEditingController(text: widget.product['Country of Origin'] ?? '');
    priceController = TextEditingController(text: widget.product['RSP']?.toString() ?? '');
    asinController = TextEditingController(text: widget.product['ASIN'] ?? '');
    ninController = TextEditingController(text: widget.product['NIN'] ?? '');
    vendorController = TextEditingController(text: widget.product['Vendor '] ?? '');
    barcodeController = TextEditingController(text: widget.product['Barcode'] ?? '');
    descriptionController = TextEditingController(text: widget.product['Description'] ?? '');
    feature1Controller = TextEditingController(text: widget.product['Feature 1'] ?? '');
    feature2Controller = TextEditingController(text: widget.product['Feature 2'] ?? '');
    feature3Controller = TextEditingController(text: widget.product['Feature 3'] ?? '');
    feature4Controller = TextEditingController(text: widget.product['Feature 4'] ?? '');
    purchaseController = TextEditingController(text: widget.product['Purchase Price']?.toString() ?? '');
    weightController = TextEditingController(text: widget.product['Weight KG']?.toString() ?? '');
    heightController = TextEditingController(text: widget.product['Height CM']?.toString() ?? '');
    lengthController = TextEditingController(text: widget.product['Length CM']?.toString() ?? '');
    widthController = TextEditingController(text: widget.product['Width CM']?.toString() ?? '');
  }

  Future<void> deleteProduct() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Product"),
        content: const Text("Are you sure you want to delete this product?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.product.id)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product deleted successfully')),
      );
      Navigator.pop(context);
    }
  }


  Future<void> _pickAndUploadImage(String key) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);

    if (result == null || result.files.isEmpty) return;

    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${result.files.single.name}';
      final ref = FirebaseStorage.instance.ref('product_images/$fileName');

      // 🔴 Delete previous image from storage (if any)
      final oldUrl = imageUrls[key];
      if (oldUrl != null && oldUrl.isNotEmpty) {
        try {
          final oldRef = FirebaseStorage.instance.refFromURL(oldUrl);
          await oldRef.delete();
        } catch (e) {
          debugPrint('Failed to delete old image: $e');
        }
      }

      // ✅ Upload new image
      UploadTask uploadTask;
      if (kIsWeb) {
        // For Web
        final Uint8List fileBytes = result.files.single.bytes!;
        uploadTask = ref.putData(fileBytes);
      } else {
        // For Mobile/Desktop
        final filePath = result.files.single.path!;
        final file = File(filePath);
        uploadTask = ref.putFile(file);
      }

      final snap = await uploadTask;
      final newUrl = await snap.ref.getDownloadURL();

      setState(() {
        imageUrls[key] = '$newUrl?ts=${DateTime.now().millisecondsSinceEpoch}'; // cache bust
      });

      // ✅ Update Firestore (save clean URL without timestamp)
      await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.product.id)
          .update({key: newUrl});

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$key updated')));
    } catch (e) {
      debugPrint('Image update failed for $key: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update $key')));
    }
  }




  Future<void> updateProduct() async {
    if (_formKey.currentState?.validate() != true) return;

    Map<String, dynamic> updateData = {
      'Brand': brandController.text.trim(),
      'Category': categoryController.text.trim(),
      'Sub Category': subCategoryController.text.trim(),
      'Country of Origin': originController.text.trim(),
      'RSP': double.tryParse(priceController.text.trim()) ?? 0.0,
      'ASIN': asinController.text.trim(),
      'NIN': ninController.text.trim(),
      'Vendor ': vendorController.text.trim(),
      'Barcode': barcodeController.text.trim(),
      'Description': descriptionController.text.trim(),
      'Feature 1': feature1Controller.text.trim(),
      'Feature 2': feature2Controller.text.trim(),
      'Feature 3': feature3Controller.text.trim(),
      'Feature 4': feature4Controller.text.trim(),
      'Purchase Price': double.tryParse(purchaseController.text.trim()) ?? 0.0,
      'Weight KG': double.tryParse(weightController.text.trim()) ?? 0.0,
      'Height CM': double.tryParse(heightController.text.trim()) ?? 0.0,
      'Length CM': double.tryParse(lengthController.text.trim()) ?? 0.0,
      'Width CM': double.tryParse(widthController.text.trim()) ?? 0.0,
    };

    // Only add changed image URLs
    for (int i = 1; i <= 5; i++) {
      final key = 'Image $i';
      final currentUrl = imageUrls[key] ?? '';
      final originalUrl = originalImageUrls[key] ?? '';
      if (currentUrl != originalUrl) {
        updateData[key] = currentUrl;
      }
    }

    await FirebaseFirestore.instance
        .collection('products')
        .doc(widget.product.id)
        .update(updateData);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Product updated successfully')),
    );
    Navigator.pop(context);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text("Product Details", style: TextStyle(color: Colors.white),)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Wrap(
              runSpacing: 12,
              children: [
            if (imageUrls.values.any((url) => url != null && url.isNotEmpty))
              CarouselSlider.builder(
                itemCount: imageUrls.entries
                    .where((e) => e.value != null && e.value!.isNotEmpty)
                    .length,
                itemBuilder: (context, index, realIndex) {
                  final filteredEntries = imageUrls.entries
                      .where((e) => e.value != null && e.value!.isNotEmpty)
                      .toList();
                  final entry = filteredEntries[index];

                  return Container(
                    width: 300, // Set your desired width
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[200],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        entry.value!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                      ),
                    ),
                  );
                },
                options: CarouselOptions(
                  height: 300, // Total height of the carousel (including image + dots)
                  enlargeCenterPage: true,
                  enableInfiniteScroll: false,
                  viewportFraction: 0.7,
                  autoPlay: false,
                  onPageChanged: (index, reason) {
                    setState(() {
                      _currentImageIndex = index;
                    });
                  },
                ),
              )
    else
    const Center(child: Text('No Images')),

                TextFormField(controller: brandController, decoration: const InputDecoration(labelText: 'Product Name'), validator: (val) => val!.isEmpty ? 'Required' : null),
                TextFormField(controller: categoryController, decoration: const InputDecoration(labelText: 'Category')),
                TextFormField(controller: subCategoryController, decoration: const InputDecoration(labelText: 'Sub Category')),
                TextFormField(controller: originController, decoration: const InputDecoration(labelText: 'Country of Origin')),
                TextFormField(controller: priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price (RSP)')),
                TextFormField(controller: asinController, decoration: const InputDecoration(labelText: 'ASIN')),
                TextFormField(controller: ninController, decoration: const InputDecoration(labelText: 'NIN')),
                TextFormField(controller: vendorController, decoration: const InputDecoration(labelText: 'Vendor')),
                TextFormField(controller: barcodeController, decoration: const InputDecoration(labelText: 'Barcode')),
                TextFormField(controller: descriptionController, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
                TextFormField(controller: feature1Controller, decoration: const InputDecoration(labelText: 'Feature 1')),
                TextFormField(controller: feature2Controller, decoration: const InputDecoration(labelText: 'Feature 2')),
                TextFormField(controller: feature3Controller, decoration: const InputDecoration(labelText: 'Feature 3')),
                TextFormField(controller: feature4Controller, decoration: const InputDecoration(labelText: 'Feature 4')),
                TextFormField(controller: purchaseController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Purchase Price')),
                TextFormField(controller: weightController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Weight (KG)')),
                TextFormField(controller: heightController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Height (CM)')),
                TextFormField(controller: lengthController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Length (CM)')),
                TextFormField(controller: widthController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Width (CM)')),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: List.generate(5, (i) {
                    final key = 'Image ${i + 1}';
                    final url = imageUrls[key];
                    return GestureDetector(
                      onTap: () async {
                        setState(() => isUploadingImage[key] = true);
                        await _pickAndUploadImage(key);
                        setState(() => isUploadingImage[key] = false);
                      },
                      child: CircleAvatar(
                        radius: 35,
                        backgroundImage: (url != null && url.isNotEmpty)
                            ? NetworkImage(url)
                            : null,
                        backgroundColor: Colors.grey[300],
                        child: isUploadingImage[key] == true
                            ? const CircularProgressIndicator()
                            : (url == null || url.isEmpty)
                            ? const Icon(Icons.add_a_photo)
                            : null,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: updateProduct,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                      child: const Text("Update Product", style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(
                      width: 20,
                    ),
                    ElevatedButton(
                      onPressed: deleteProduct,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text("Delete Product", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
