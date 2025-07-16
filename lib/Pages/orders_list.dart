import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vendor/Pages/orders_details.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String? vendorName;

  @override
  void initState() {
    super.initState();
    _loadVendorName();
  }

  Future<void> _loadVendorName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      vendorName = prefs.getString('vendorName');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('vendor', isEqualTo: vendorName) // 🔥 Filter by logged-in vendor
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Error loading orders'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final orders = snapshot.data!.docs;

          if (orders.isEmpty) {
            return const Center(child: Text("No orders available for this vendor."));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return IntrinsicWidth(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(Colors.grey[200]),
                      columns: const [
                        DataColumn(label: Text('PO')),
                        DataColumn(label: Text('Vendor')),
                        DataColumn(label: Text('Created')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: orders.map((order) {
                        final data = order.data() as Map<String, dynamic>;
                        final products = data['products'] as List<dynamic>;
                        final allConfirmed = products.every((p) => (p['confirmed'] ?? 0) > 0);
                        return DataRow(
                          cells: [
                            DataCell(Text(data['amazonPONumber'] ?? '')),
                            DataCell(Text(data['vendor'] ?? '')),
                            DataCell(Text(
                              DateFormat("dd MMM hh:mm a").format(data['createdAt'].toDate()),
                              overflow: TextOverflow.ellipsis,
                            )),
                            DataCell(
                              Text(
                                allConfirmed ? 'Confirmed' : 'Pending',
                                style: TextStyle(color: allConfirmed ? Colors.green : Colors.orange),
                              ),
                            ),
                            DataCell(
                              TextButton(
                                child: const Text("See Details"),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => OrderDetailsPage(order: order),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
