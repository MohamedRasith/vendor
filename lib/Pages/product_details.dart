import 'package:flutter/material.dart';

class ProductDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product['Product Title'] ?? 'Product Details'),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            product["Image 1"] != null && product["Image 1"].toString().isNotEmpty
                ? Image.network(product["Image 1"], height: 200, width: double.infinity, fit: BoxFit.cover)
                : const Icon(Icons.image_not_supported, size: 100),

            const SizedBox(height: 16),
            Text("Title: ${product['Product Title'] ?? 'N/A'}", style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text("Vendor: ${product['Vendor'] ?? 'N/A'}"),
            const SizedBox(height: 8),
            Text("Price: AED ${product['Purchase Price'] ?? '0.00'}"),
            const SizedBox(height: 8),
            Text("Category: ${product['Category'] ?? 'N/A'}"),
            const SizedBox(height: 8),
            Text("Description:\n${product['Description'] ?? 'No description'}"),
          ],
        ),
      ),
    );
  }
}
