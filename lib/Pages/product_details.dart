import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:vendor/model/products_model.dart';

class ProductDetailPage extends StatefulWidget {
  ProductModel productData;
  final dynamic productId;

  ProductDetailPage({super.key, required this.productData, required this.productId});


  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late TextEditingController nameController;
  late TextEditingController descriptionController;
  late TextEditingController priceController;
  late TextEditingController stockController;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.productData.name);
    descriptionController = TextEditingController(text: widget.productData.description);
    priceController = TextEditingController(text: widget.productData.price.toString());
    stockController = TextEditingController(text: widget.productData.totalCount.toString());
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    stockController.dispose();
    super.dispose();
  }

  Future<void> updateProduct() async {
    try {
      setState(() {
        isLoading = true;
      });
      await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId) // Make sure this ID is passed in productData
          .update({
        'name': nameController.text,
        'description': descriptionController.text,
        'price': double.tryParse(priceController.text) ?? 0,
        'totalCount': int.tryParse(stockController.text) ?? 0,
      });
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Product updated successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Edit Product")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey[300],
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: widget.productData.imageUrl,
                  width: 60,
                  height: 80,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => CircularProgressIndicator(),
                  errorWidget: (context, url, error) => Icon(Icons.error),
                ),
              ),
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: nameController,
              decoration: InputDecoration(labelText: "Product Name"),
            ),
            TextFormField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: "Description"),
            ),
            TextFormField(
              controller: priceController,
              decoration: InputDecoration(labelText: "Price"),
              keyboardType: TextInputType.number,
            ),
            TextFormField(
              controller: stockController,
              decoration: InputDecoration(labelText: "In Stock"),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: MaterialButton(
                onPressed: updateProduct,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                  side: BorderSide(color: Colors.purple.shade800, width: 2),
                ),
                padding: EdgeInsets.symmetric(vertical: 15),
                minWidth: 200,
                color: Colors.purple.shade800,
                child: isLoading?
                SizedBox(
                  width: 50,
                  child: Center(child: SpinKitThreeBounce(
                    color: Colors.white,
                    size: 30.0,
                  ),),
                )
                    :Text(
                  'Update Product',
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
