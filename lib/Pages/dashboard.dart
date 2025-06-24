import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:universal_html/html.dart' as html;
import 'package:vendor/Pages/add_orders.dart';
import 'package:vendor/Pages/add_products.dart';
import 'package:excel/excel.dart';
import 'package:vendor/Pages/edit_products.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int selectedIndex = 0;

  bool get hasActiveFilters =>
      selectedBrands.isNotEmpty || selectedVendors.isNotEmpty;

  TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  List<String> selectedVendors = [];
  List<String> selectedBrands = [];
  List<QueryDocumentSnapshot> filterProducts = [];
  bool showFilter = false;

  final List<String> titles = ['Home', 'Orders', 'Products', 'Vendor'];
  final List<IconData> icons = [
    Icons.home,
    Icons.shopping_cart,
    Icons.inventory,
    Icons.store
  ];

  bool isLoading = false;

  Future<void> pickAndUploadExcel() async {
    setState(() => isLoading = true);

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (result != null && result.files.single.bytes != null) {
      final bytes = result.files.single.bytes!;
      final excel = Excel.decodeBytes(bytes);

      final sheet = excel.tables[excel.tables.keys.first];
      if (sheet == null) return;

      List<Map<String, dynamic>> products = [];
      final header =
          sheet.rows[0].map((cell) => cell?.value.toString() ?? '').toList();

      for (int i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        Map<String, dynamic> product = {};

        for (int j = 0; j < header.length; j++) {
          final key = header[j];
          final cell = row[j];

          // Convert the cell value to string or primitive type
          final value = cell?.value;

          if (value is String ||
              value is num ||
              value is bool ||
              value == null) {
            product[key] = value;
          } else {
            product[key] = value.toString(); // fallback to string
          }
        }

        products.add(product);
      }

      // Upload to Firestore
      for (var product in products) {
        try {
          await FirebaseFirestore.instance.collection('products').add(product);
        } catch (e) {
          print('Error uploading product: $e');
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Successfully imported ${products.length} products')),
      );
    }

    setState(() => isLoading = false);
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

  void exportFilteredProductsToExcelWeb(
      List<QueryDocumentSnapshot> filteredProducts) {
    final excel = Excel.createExcel();
    final String oldSheetName = excel.getDefaultSheet()!;
    excel.rename(oldSheetName, 'Products');
    final sheet = excel['Products'];

    // Add headers
    sheet.appendRow([
      TextCellValue('Brand'),
      TextCellValue('Product Title'),
      TextCellValue('Barcode'),
      TextCellValue('ASIN'),
      TextCellValue('NIN'),
      TextCellValue('Description'),
      TextCellValue('Category'),
      TextCellValue('Sub Category'),
      TextCellValue('Feature 1'),
      TextCellValue('Feature 2'),
      TextCellValue('Feature 3'),
      TextCellValue('Feature 4'),
      TextCellValue('Image 1'),
      TextCellValue('Image 2'),
      TextCellValue('Image 3'),
      TextCellValue('Image 4'),
      TextCellValue('Image 5'),
      TextCellValue('Weight KG'),
      TextCellValue('Length CM'),
      TextCellValue('Width CM'),
      TextCellValue('Height CM'),
      TextCellValue('Country of Origin'),
      TextCellValue('HSN Code'),
      TextCellValue('Vendor'),
      TextCellValue('Purchase Price'),
      TextCellValue('RSP'),
    ]);


    // Add product rows
    for (var product in filteredProducts) {
      sheet.appendRow([
        TextCellValue(product['Brand']?.toString() ?? ''),
        TextCellValue(product['Product Title']?.toString() ?? ''),
        TextCellValue(product['Barcode']?.toString() ?? ''),
        TextCellValue(product['ASIN']?.toString() ?? ''),
        TextCellValue(product['NIN']?.toString() ?? ''),
        TextCellValue(product['Description']?.toString() ?? ''),
        TextCellValue(product['Category']?.toString() ?? ''),
        TextCellValue(product['Sub Category']?.toString() ?? ''),
        TextCellValue(product['Feature 1']?.toString() ?? ''),
        TextCellValue(product['Feature 2']?.toString() ?? ''),
        TextCellValue(product['Feature 3']?.toString() ?? ''),
        TextCellValue(product['Feature 4']?.toString() ?? ''),
        TextCellValue(product['Image 1']?.toString() ?? ''),
        TextCellValue(product['Image 2']?.toString() ?? ''),
        TextCellValue(product['Image 3']?.toString() ?? ''),
        TextCellValue(product['Image 4']?.toString() ?? ''),
        TextCellValue(product['Image 5']?.toString() ?? ''),
        TextCellValue(product['Weight KG']?.toString() ?? ''),
        TextCellValue(product['Length CM']?.toString() ?? ''),
        TextCellValue(product['Width CM']?.toString() ?? ''),
        TextCellValue(product['Height CM']?.toString() ?? ''),
        TextCellValue(product['Country of Origin']?.toString() ?? ''),
        TextCellValue(product['HSN Code']?.toString() ?? ''),
        TextCellValue(product['Vendor ']?.toString() ?? ''),
        TextCellValue(product['Purchase Price']?.toString() ?? ''),
        TextCellValue(product['RSP']?.toString() ?? ''),
      ]);
    }


    // Convert to bytes
    final List<int>? bytes = excel.encode();
    if (bytes == null) return;

    // Convert to Blob for web
    final content = Uint8List.fromList(bytes);
    final blob = html.Blob([content]);
    final url = html.Url.createObjectUrlFromBlob(blob);

    // Trigger download
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'products_export.xlsx')
      ..click();

    // Cleanup
    html.Url.revokeObjectUrl(url);
  }

  Widget getOrdersPageContent() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Error: \${snapshot.error}'));
        }

        final orders = snapshot.data?.docs ?? [];

        if (orders.isEmpty) {
          return Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddOrderPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              child: const Text("Add Orders"),
            ),
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const AddOrderPage()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      child: const Text("Add Orders"),
                    ),
                  ),
                  Center(
                    child: isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton.icon(
                            onPressed: pickAndUploadExcel,
                            // Implement excel import logic
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Import Excel File'),
                          ),
                  ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Colors.grey.shade300, width: 1),
                    ),
                    elevation: 4,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          child: IntrinsicWidth(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                  minWidth: constraints.maxWidth),
                              child: DataTable(
                                columnSpacing: 20,
                                dataRowMinHeight: 50,
                                dataRowMaxHeight: 60,
                                columns: const [
                                  DataColumn(label: Text('Amazon PO')),
                                  DataColumn(label: Text('BNB PO')),
                                  DataColumn(label: Text('Vendor')),
                                  DataColumn(label: Text('Delivery Location')),
                                  DataColumn(label: Text('ASN')),
                                  DataColumn(label: Text('Appointment ID')),
                                  DataColumn(label: Text('Appointment Date')),
                                ],
                                rows: orders.map((order) {
                                  final Timestamp? ts = order['appointmentDate'];
                                  final String formattedDate = ts != null
                                      ? DateFormat('yyyy-MM-dd hh:mm a')
                                          .format(ts.toDate())
                                      : '';
                                  return DataRow(cells: [
                                    DataCell(Text(order['amazonPONumber'] ?? '')),
                                    DataCell(Text(order['bnbPONumber'] ?? '')),
                                    DataCell(Text(order['vendor'] ?? '')),
                                    DataCell(Text(order['location'] ?? '')),
                                    DataCell(Text(order['asn'] ?? '')),
                                    DataCell(Text(order['appointmentId'] ?? '')),
                                    DataCell(Text(formattedDate)),
                                  ]);
                                }).toList(),
                              ),
                            ),
                          ),
                        );
                      }
                    ),
                  ),
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget getProductsPageContent() {
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AddProductPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  child: const Text("Add Products"),
                ),
              ),
              Center(
                child: isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton.icon(
                        onPressed: pickAndUploadExcel,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Import Excel File'),
                      ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {
                  if (filterProducts.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No products to export.')),
                    );
                  } else {
                    exportFilteredProductsToExcelWeb(filterProducts);
                  }
                },
                icon: const Icon(Icons.download),
                label: const Text("Export Excel"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    labelText: 'Search by ASIN or Barcode',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery =
                          value.length >= 3 ? value.toLowerCase() : '';
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
            ])),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance.collection('products').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final products = snapshot.data?.docs ?? [];

              if (products.isEmpty) {
                // No products: Show button centered
                return Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AddProductPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    child: const Text("Add Products"),
                  ),
                );
              } else {
                // Products exist: show button on top + list below
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Card(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                                color: Colors.grey.shade300, width: 1),
                          ),
                          elevation: 4,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final filteredProducts =
                                  products.where((product) {
                                final brand = (product['Brand'] ?? '')
                                    .toString()
                                    .toLowerCase();
                                final asin = (product['ASIN'] ?? '')
                                    .toString()
                                    .toLowerCase();
                                final barcode = (product['Barcode'] ?? '')
                                    .toString()
                                    .toLowerCase();
                                final vendor =
                                    (product['Vendor '] ?? '').toString();

                                final matchesSearch = searchQuery.isEmpty ||
                                    brand.contains(searchQuery.toLowerCase()) ||
                                    asin.contains(searchQuery.toLowerCase()) ||
                                    barcode
                                        .contains(searchQuery.toLowerCase()) ||
                                    vendor.contains(searchQuery.toLowerCase());

                                final matchesBrandFilter = selectedBrands
                                        .isEmpty ||
                                    selectedBrands.contains(product['Brand']);
                                final matchesVendorFilter =
                                    selectedVendors.isEmpty ||
                                        selectedVendors.contains(vendor);

                                return matchesSearch &&
                                    matchesBrandFilter &&
                                    matchesVendorFilter;
                              }).toList();
                              filterProducts = filteredProducts;
                              return filteredProducts.isEmpty
                                  ? const Center(
                                      child: Text("No Products Found"),
                                    )
                                  : SingleChildScrollView(
                                      child: IntrinsicWidth(
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                              minWidth: constraints.maxWidth),
                                          child: DataTable(
                                            columnSpacing: 20,
                                            dataRowMinHeight: 50,
                                            dataRowMaxHeight: 100,
                                            columns: const [
                                              DataColumn(
                                                  label: Text('Product Name')),
                                              DataColumn(label: Text('ASIN')),
                                              DataColumn(
                                                  label: Text('Barcode')),
                                              DataColumn(
                                                  label: Text('Cost(exc.VAT)')),
                                              DataColumn(
                                                  label: Text('RSP(exc.VAT)')),
                                              DataColumn(
                                                  label: Text('Vendor Name')),
                                            ],
                                            rows:
                                                filteredProducts.map((product) {
                                              return DataRow(cells: [
                                                DataCell(Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    product['Image 1'] !=
                                                                null &&
                                                            product['Image 1']
                                                                .isNotEmpty
                                                        ? ClipRRect(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                            child:
                                                                Image.network(
                                                              product[
                                                                  'Image 1'],
                                                              width: 50,
                                                              height: 50,
                                                              fit: BoxFit.cover,
                                                            ),
                                                          )
                                                        : Container(
                                                            width: 30,
                                                            height: 30,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors
                                                                  .grey[300],
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                            ),
                                                            child: const Icon(
                                                                Icons
                                                                    .image_not_supported,
                                                                size: 16),
                                                          ),
                                                    const SizedBox(width: 8),
                                                    Flexible(
                                                      child: MouseRegion(
                                                        cursor:
                                                            SystemMouseCursors
                                                                .click,
                                                        child: GestureDetector(
                                                          onTap: () {
                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder: (_) =>
                                                                    EditProductPage(
                                                                        product:
                                                                            product),
                                                              ),
                                                            );
                                                          },
                                                          child: Text(
                                                            _wrapBrandText(
                                                                product['Brand'] ??
                                                                    'No Name'),
                                                            maxLines: 5,
                                                            softWrap: true,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style:
                                                                const TextStyle(
                                                              color:
                                                                  Colors.blue,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                )),
                                                DataCell(Text(
                                                    product['ASIN'] ?? '')),
                                                DataCell(Text(
                                                    product['Barcode'] ?? '')),
                                                DataCell(Text(
                                                    'AED ${product['Purchase Price'] ?? '0.00'}')),
                                                DataCell(Text(
                                                    'AED ${product['RSP'] ?? '0.00'}')),
                                                DataCell(Text(
                                                    product['Vendor '] ?? '')),
                                              ]);
                                            }).toList(),
                                          ),
                                        ),
                                      ),
                                    );
                            },
                          ),
                        ),
                      ),
                    )
                  ],
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget getSelectedPageContent() {
    switch (selectedIndex) {
      case 0:
        return const Center(
            child:
                Text("Welcome to Home Page", style: TextStyle(fontSize: 24)));
      case 1:
        return getOrdersPageContent();
      case 2:
        return getProductsPageContent();
      case 3:
        return const Center(
            child: Text("Vendor Page", style: TextStyle(fontSize: 24)));
      default:
        return const Center(child: Text("Unknown Page"));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: isMobile
          ? AppBar(
              backgroundColor: Colors.blueGrey[900],
              title: Text(titles[selectedIndex],
                  style: const TextStyle(color: Colors.white)),
              iconTheme: const IconThemeData(color: Colors.white),
            )
          : null,
      drawer: isMobile
          ? Drawer(
              child: Column(
                children: [
                  const SizedBox(height: 50),
                  ...List.generate(titles.length, (index) {
                    return ListTile(
                      leading: Icon(
                        icons[index],
                        color:
                            selectedIndex == index ? Colors.black : Colors.grey,
                      ),
                      title: Text(
                        titles[index],
                        style: TextStyle(
                          fontWeight: selectedIndex == index
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          selectedIndex = index;
                        });
                        Navigator.pop(context); // Close drawer
                      },
                    );
                  }),
                ],
              ),
            )
          : null,
      body: Row(
        children: [
          if (!isMobile)
            Container(
              width: 200,
              color: Colors.blueGrey[900],
              child: Column(
                children: [
                  const SizedBox(height: 50),
                  ...List.generate(titles.length, (index) {
                    return ListTile(
                      leading: Icon(
                        icons[index],
                        color:
                            selectedIndex == index ? Colors.white : Colors.grey,
                      ),
                      title: Text(
                        titles[index],
                        style: TextStyle(
                          color: selectedIndex == index
                              ? Colors.white
                              : Colors.grey,
                          fontWeight: selectedIndex == index
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      selected: selectedIndex == index,
                      selectedTileColor: Colors.blueGrey[700],
                      onTap: () {
                        setState(() {
                          selectedIndex = index;
                        });
                      },
                    );
                  }),
                ],
              ),
            ),
          Expanded(
            child: Container(
              color: Colors.grey[100],
              padding: const EdgeInsets.all(16),
              child: getSelectedPageContent(),
            ),
          ),
        ],
      ),
    );
  }
}
