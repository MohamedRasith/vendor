import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  Map<String, String?> imageUrls = {};

  @override
  void initState() {
    super.initState();
    final data = widget.product.data() as Map<String, dynamic>;
    for (int i = 1; i <= 5; i++) {
      imageUrls['Image $i'] = data['Image $i'] as String? ?? '';
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
    if (result?.files.single.path == null) return;

    final file = File(result!.files.single.path!);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${result.files.single.name}';
    final ref = FirebaseStorage.instance.ref('product_images/$fileName');

    final snap = await ref.putFile(file);
    final url = await snap.ref.getDownloadURL();

    // Update Firestore
    await FirebaseFirestore.instance
        .collection('products')
        .doc(widget.product.id)
        .update({key: url});

    setState(() { imageUrls[key] = url; });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$key updated')));
  }

  Future<void> updateProduct() async {
    if (_formKey.currentState?.validate() != true) return;

    await FirebaseFirestore.instance.collection('products').doc(widget.product.id).update({
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
      'Image 1': imageUrls.length > 0 ? imageUrls[0] : "",
      'Image 2': imageUrls.length > 1 ? imageUrls[1] : "",
      'Image 3': imageUrls.length > 2 ? imageUrls[2] : "",
      'Image 4': imageUrls.length > 3 ? imageUrls[3] : "",
      'Image 5': imageUrls.length > 4 ? imageUrls[4] : ""
    });

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
                Center(
                  child: CircleAvatar(
                    radius: 30, // You can adjust the radius
                    backgroundImage: NetworkImage(widget.product['Image 1']),
                    backgroundColor: Colors.grey[200], // Optional: fallback background
                  ),
                ),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(5, (i) {
                    final key = 'Image ${i + 1}';
                    final url = imageUrls[key];
                    return GestureDetector(
                      onTap: () => _pickAndUploadImage(key),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundImage: (url != null && url.isNotEmpty)
                            ? NetworkImage(url)
                            : null,
                        backgroundColor: Colors.grey[200],
                        child: (url == null || url.isEmpty)
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
