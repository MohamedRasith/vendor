import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:vendor/Pages/product_details.dart';

import '../model/products_model.dart';


class ProductsList extends StatefulWidget {
  const ProductsList({super.key});


  @override
  State<ProductsList> createState() => _ProductsListState();
}

class _ProductsListState extends State<ProductsList> {
  Future<String?> getFullName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data()?['fullName'];
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Products')),
      body: FutureBuilder<String?>(
          future: getFullName(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            final fullName = snapshot.data;
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('products')
                .where('vendorName', isEqualTo: fullName)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return  Center(child: SpinKitThreeBounce(
                  color: Colors.purple.shade800,
                  size: 30.0,
                ),);
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text('No products found'));
              }

              var products = snapshot.data!.docs.map((doc) => ProductModel.fromFirestore(doc.data() as Map<String, dynamic>)).toList();

              return ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, index) {
                  var product = products[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 30, // Adjust size as needed
                        backgroundColor: Colors.grey[300], // Placeholder background color
                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: product.imageUrl,
                            width: 60,  // Match the CircleAvatar size
                            height: 80,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => CircularProgressIndicator(), // Loader
                            errorWidget: (context, url, error) => Icon(Icons.error), // Error icon
                          ),
                        ),
                      ),
                      title: Text(product.name),
                      subtitle: Text(product.description),
                      onTap: () {
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(
                        //     builder: (context) => ProductDetailPage(productData: product, productId: product.id),
                        //   ),
                        // );
                      },
                    ),
                  );
                },
              );
            },
          );
        }
      ),
    );
  }
}
