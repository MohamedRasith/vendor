import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:vendor/Pages/product_details.dart';

class ProductsListScreen extends StatefulWidget {
  final String vendorName;

  const ProductsListScreen({super.key, required this.vendorName});

  @override
  State<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends State<ProductsListScreen> {
  String searchText = '';
  TextEditingController searchController = TextEditingController();

  String _insertLineBreaks(String text, int interval) {
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i + 1) % interval == 0 && i != text.length - 1) {
        buffer.write('\n');
      }
    }
    return buffer.toString();
  }

  String _wrapBrandText(String text, [int chunkSize = 40]) {
    if (text.length <= chunkSize) return text;

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i += chunkSize) {
      final end = (i + chunkSize < text.length) ? i + chunkSize : text.length;
      buffer.writeln(text.substring(i, end));
    }
    return buffer.toString().trim();
  }



  @override
  Widget build(BuildContext context) {
    final productQuery = FirebaseFirestore.instance
        .collection('products')
        .where('Vendor', isEqualTo: widget.vendorName);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('${widget.vendorName} Products', style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 🔍 Search Bar
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: 'Search Product Title',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  searchText = value.trim().toLowerCase();
                });
              },
            ),
            const SizedBox(height: 16),

            // 📦 Products Table
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: productQuery.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final docs = snapshot.data?.docs ?? [];

                  final filteredDocs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final title = (data['Product Title'] ?? '').toString().toLowerCase();
                    return searchText.length < 3 || title.contains(searchText);
                  }).toList();

                  if (filteredDocs.isEmpty) {
                    return const Center(child: Text('No products found'));
                  }

                  return SingleChildScrollView(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return IntrinsicWidth(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minWidth: constraints.maxWidth),
                            child: DataTable(
                              columnSpacing: 20,
                              dataRowMinHeight: 50,
                              dataRowMaxHeight: 100,
                              showCheckboxColumn: false, // ✅ Remove checkbox
                              headingRowColor: MaterialStateProperty.all(Colors.grey[200]),
                              columns: const [
                                DataColumn(label: Text('Title')),
                                DataColumn(label: Text('ASIN')),
                                DataColumn(
                                    label: Text('Barcode')),
                                DataColumn(
                                    label: Text('Cost(exc.VAT)')),
                                DataColumn(
                                    label: Text('RSP(exc.VAT)')),
                                DataColumn(
                                    label: Text("VAT(5%)")
                                ),
                              ],
                              rows: filteredDocs.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;

                                return DataRow(
                                  cells: [
                                    DataCell(Row(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.center,
                                      children: [
                                        Stack(
                                          alignment: Alignment.topRight,
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: data['Image 1'] != null && data['Image 1'] is String && data['Image 1'].isNotEmpty
                                                  ? Image.network(
                                                data['Image 1'],
                                                width: 50,
                                                height: 50,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Container(
                                                    width: 50,
                                                    height: 50,
                                                    color: Colors.grey[200],
                                                    alignment: Alignment.center,
                                                    child: const Icon(Icons.broken_image, size: 24),
                                                  );
                                                },
                                              )
                                                  : Container(
                                                width: 50,
                                                height: 50,
                                                color: Colors.grey[200],
                                                alignment: Alignment.center,
                                                child: const Icon(Icons.image_not_supported, size: 24),
                                              ),
                                            ),
                                            // Badge
                                          ],
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: MouseRegion(
                                            cursor: SystemMouseCursors.click,
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // Brand Text (Navigates to EditProductPage)
                                                Expanded(
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      // Navigator.push(
                                                      //   context,
                                                      //   MaterialPageRoute(
                                                      //     builder: (_) => EditProductPage(product: product),
                                                      //   ),
                                                      // );
                                                    },
                                                    child: Text(
                                                      _wrapBrandText(data['Product Title'] ?? 'No Name'),
                                                      maxLines: 5,
                                                      softWrap: true,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        color: Colors.blue,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ),

                                                const SizedBox(width: 4),

                                                // Copy Icon with Tooltip
                                                Tooltip(
                                                  message: 'Copy Product Title',
                                                  child: InkWell(
                                                    onTap: () {
                                                      Clipboard.setData(
                                                        ClipboardData(text: data['Product Title'] ?? ''),
                                                      );
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(content: Text('Product Title copied')),
                                                      );
                                                    },
                                                    child: const Icon(Icons.copy, size: 16, color: Colors.grey),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    )),
                                    DataCell(Tooltip(
                                      message: 'Click to copy ASIN',
                                      child: InkWell(
                                        onTap: () {
                                          Clipboard.setData(ClipboardData(text: data['ASIN'] ?? ''));
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('ASIN copied')),
                                          );
                                        },
                                        child: Text(data['ASIN'] ?? ''),
                                      ),
                                    ),),
                                    DataCell(Tooltip(
                                      message: 'Click to copy Barcode',
                                      child: InkWell(
                                        onTap: () {
                                          Clipboard.setData(ClipboardData(text: data['Barcode'] ?? ''));
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Barcode copied')),
                                          );
                                        },
                                        child: Text(data['Barcode'] ?? ''),
                                      ),
                                    ),),
                                    DataCell(
                                      Tooltip(
                                        message: 'Click to copy Purchase Price',
                                        child: InkWell(
                                          onTap: () {
                                            Clipboard.setData(
                                              ClipboardData(text: 'AED ${data['Purchase Price'] ?? '0.00'}'),
                                            );
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Purchase Price copied')),
                                            );
                                          },
                                          child: Text('AED ${data['Purchase Price'] ?? '0.00'}'),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Tooltip(
                                        message: 'Click to copy RSP',
                                        child: InkWell(
                                          onTap: () {
                                            Clipboard.setData(
                                              ClipboardData(text: 'AED ${data['RSP'] ?? '0.00'}'),
                                            );
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('RSP copied')),
                                            );
                                          },
                                          child: Text('AED ${data['RSP'] ?? '0.00'}'),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Builder(
                                        builder: (context) {
                                          final rawRSP = data['RSP'];
                                          final rsp = double.tryParse(rawRSP?.toString() ?? '0') ?? 0.0;
                                          final vat = rsp * 0.05;
                                          final total = rsp + vat;

                                          return Tooltip(
                                            message: 'Click to copy RSP + VAT',
                                            child: InkWell(
                                              onTap: () {
                                                Clipboard.setData(
                                                  ClipboardData(text: 'AED ${total.toStringAsFixed(2)}'),
                                                );
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('RSP + VAT copied')),
                                                );
                                              },
                                              child: Text('AED ${total.toStringAsFixed(2)}'),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                  onSelectChanged: (_) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ProductDetailsScreen(product: data),
                                      ),
                                    );
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                        );
                      }
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
