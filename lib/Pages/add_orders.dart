import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AddOrderPage extends StatefulWidget {
  const AddOrderPage({super.key});

  @override
  State<AddOrderPage> createState() => _AddOrderPageState();
}

class _AddOrderPageState extends State<AddOrderPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController poNumberController = TextEditingController();
  final TextEditingController bnbPoNumberController = TextEditingController();
  final TextEditingController asnController = TextEditingController();
  final TextEditingController appointmentIdController = TextEditingController();
  TextEditingController productNosController = TextEditingController();
  DateTime? appointmentDate;

  String? selectedVendor;
  String? selectedLocation;
  bool isLoading = false;
  PlatformFile? appointmentFile;
  PlatformFile? bnbInvoiceFile;

  List<String> vendors = ["Vendor A", "Vendor B", "Vendor C"];
  List<String> locations = ["Dubai", "Abu Dhabi", "Sharjah"];
  List<DocumentSnapshot> productSuggestions = [];
  final TextEditingController productSearchController = TextEditingController();
  OverlayEntry? overlayEntry;
  final LayerLink _layerLink = LayerLink();
  int productNos = 1;

  List<Map<String, dynamic>> productDetails = [];

  final TextEditingController asinController = TextEditingController();
  final TextEditingController barcodeController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController requestedUnitsController = TextEditingController();
  final TextEditingController confirmedDetailsController = TextEditingController();
  final TextEditingController unitCostController = TextEditingController();
  final LayerLink _asinLayerLink = LayerLink();
  OverlayEntry? _asinOverlayEntry;
  List<Map<String, dynamic>> asinSearchResults = [];


  @override
  void initState() {
    super.initState();
    fetchVendors();
    productNosController = TextEditingController(text: productNos.toString());
  }
  void fetchAsinSearch(String input) async {
    if (input.length < 3) {
      _asinOverlayEntry?.remove();
      _asinOverlayEntry = null;
      return;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('keywords', arrayContains: input.toLowerCase()) // you must maintain this array in each product
        .limit(5)
        .get();

    asinSearchResults = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    showAsinOverlay();
  }
  void showAsinOverlay() {
    _asinOverlayEntry?.remove();

    final overlayState = Overlay.of(context);
    if (overlayState == null || !mounted || asinSearchResults.isEmpty) return;

    _asinOverlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 300,
        child: CompositedTransformFollower(
          link: _asinLayerLink,
          offset: const Offset(0, 40),
          showWhenUnlinked: false,
          child: Material(
            elevation: 4,
            color: Colors.white,
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: asinSearchResults.length,
              itemBuilder: (context, index) {
                final product = asinSearchResults[index];
                return ListTile(
                  dense: true,
                  title: Text(product['Product Title'] ?? ''),
                  subtitle: Text('ASIN: ${product['ASIN']} | Barcode: ${product['Barcode']}'),
                  onTap: () {
                    asinController.text = product['ASIN'] ?? '';
                    barcodeController.text = product['Barcode'] ?? '';
                    titleController.text = product['Product Title'] ?? '';
                    unitCostController.text = product['RSP']?.toString() ?? '';
                    requestedUnitsController.text = '1';
                    confirmedDetailsController.text = '0';
                    _asinOverlayEntry?.remove();
                    _asinOverlayEntry = null;
                    FocusScope.of(context).unfocus();
                  },
                );
              },
            ),
          ),
        ),
      ),
    );

    overlayState.insert(_asinOverlayEntry!);
  }

  void searchProducts(String query) async {
    // Remove overlay and clear suggestions if query is too short or empty
    if (query.isEmpty || query.length < 3) {
      setState(() {
        productSuggestions = [];
      });
      overlayEntry?.remove();
      overlayEntry = null;
      return;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('products')
        .limit(50) // Limit for performance
        .get();

    final results = snapshot.docs.where((doc) {
      final data = doc.data();
      final q = query.toLowerCase();
      return (data['Brand']?.toString().toLowerCase().contains(q) ?? false) ||
          (data['Product Title']?.toString().toLowerCase().contains(q) ?? false) ||
          (data['ASIN']?.toString().toLowerCase().contains(q) ?? false) ||
          (data['Barcode']?.toString().toLowerCase().contains(q) ?? false);
    }).toList();

    setState(() {
      productSuggestions = results;
    });

    showSuggestionsOverlay();
  }


  Future<void> pickFile(String type) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png'],
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        if (type == 'appointment') {
          appointmentFile = result.files.first;
        } else if (type == 'bnb') {
          bnbInvoiceFile = result.files.first;
        }
      });
    }
  }

  double calculateTotal() {
    final confirmed = int.tryParse(confirmedDetailsController.text) ?? 0;
    final cost = double.tryParse(unitCostController.text) ?? 0.0;
    return confirmed * cost;
  }

  void addProductRow() async {
    if (asinController.text.isEmpty || titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ASIN and Title are required")),
      );
      return;
    }

    final newRow = {
      'asin': asinController.text.trim(),
      'barcode': barcodeController.text.trim(),
      'title': titleController.text.trim(),
      'requested': requestedUnitsController.text.trim(),
      'confirmed': confirmedDetailsController.text.trim(),
      'unitCost': unitCostController.text.trim(),
      'total': calculateTotal().toStringAsFixed(2),
      'orderId': poNumberController.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    };

    // First save to Firebase
    final docRef = await FirebaseFirestore.instance.collection('order_items').add(newRow);

    // Now update the same document to include its ID
    await docRef.update({'firebaseId': docRef.id});

    // Add ID to local map
    final rowWithId = Map<String, dynamic>.from(newRow);
    rowWithId['firebaseId'] = docRef.id;

    setState(() {
      productDetails.add(rowWithId); // Store with ID
      asinController.clear();
      barcodeController.clear();
      titleController.clear();
      requestedUnitsController.clear();
      confirmedDetailsController.clear();
      unitCostController.clear();
    });
  }



  void deleteProductRow(int index) async {
    if (index < 0 || index >= productDetails.length) {
      debugPrint("Invalid index: $index");
      return;
    }

    final firebaseId = productDetails[index]['firebaseId'];

    setState(() {
      productDetails.removeAt(index);
    });

    // Delete from Firestore only if firebaseId is not null
    if (firebaseId != null) {
      await FirebaseFirestore.instance.collection('order_items').doc(firebaseId).delete();
    }
  }



  void showSuggestionsOverlay() {
    if (overlayEntry != null) {
      setState(() {
        overlayEntry!.remove();
        overlayEntry = null;
      });

    }

    final renderBox = context.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? const Size(300, 200);

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width - 32,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0.0, 40.0),
          child: Material(
            elevation: 4.0,
            child: Column(
              children: [
                SizedBox(
                  height: 200,
                  child: productSuggestions.isEmpty
                      ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text("No products found", style: TextStyle(color: Colors.grey)),
                    ),
                  )
                      : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: productSuggestions.length,
                    itemBuilder: (context, index) {
                      final product = productSuggestions[index];
                      return ListTile(
                        title: Text(product['Brand']),
                        onTap: () {
                          productSearchController.text = product['Brand'];
                          asinController.text = product['ASIN'] ?? '';
                          barcodeController.text = product['Barcode'] ?? '';
                          titleController.text = product['Product Title'] ?? '';
                          unitCostController.text = product['RSP']?.toString() ?? '';
                          overlayEntry?.remove();
                          overlayEntry = null;
                        },
                      );
                    },
                  ),
                ),
                Center(child: IconButton(
                    onPressed: (){
                      setState(() {
                        overlayEntry?.remove();
                      });

                    },
                    icon: const Icon(Icons.close)),)
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry!);
  }




  void updateBNBPO() {
    final amazonPO = poNumberController.text.trim();
    final vendor = selectedVendor ?? "";
    if (amazonPO.isNotEmpty && vendor.isNotEmpty) {
      bnbPoNumberController.text = "$amazonPO-$vendor";
    }
  }

  Future<void> fetchVendors() async {
    final snapshot = await FirebaseFirestore.instance.collection('products').get();
    setState(() {
      vendors = snapshot.docs.map((doc) => doc['Vendor '] as String).toList();
    });
  }

  Future<void> selectAppointmentDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        setState(() {
          appointmentDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
      }
    }
  }

  void submitOrder() async {
    if (!_formKey.currentState!.validate() || appointmentDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    final orderData = {
      'amazonPONumber': poNumberController.text.trim(),
      'bnbPONumber': bnbPoNumberController.text.trim(),
      'asn': asnController.text.trim(),
      'productName': productSearchController.text.trim(),
      'productQuantity': productNos,
      'appointmentId': appointmentIdController.text.trim(),
      'appointmentDate': appointmentDate,
      'vendor': selectedVendor,
      'location': selectedLocation,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance.collection('orders').add(orderData);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Order added successfully")),
    );
    setState(() {
      isLoading = false;
      poNumberController.clear();
      bnbPoNumberController.clear();
      asnController.clear();
      appointmentIdController.clear();
      selectedVendor = null;
      selectedLocation = null;
      appointmentDate = null;
    });
  }

  @override
  void dispose() {
    overlayEntry?.remove();
    productSearchController.dispose();
    poNumberController.dispose();
    bnbPoNumberController.dispose();
    asnController.dispose();
    appointmentIdController.dispose();
    productNosController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Add Orders", style: TextStyle(color: Colors.white),),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Form Section
                  Expanded(
                    flex: 2,
                    child: Form(
                      key: _formKey,
                      child: Wrap(
                        runSpacing: 12,
                        children: [
                          TextFormField(
                            controller: poNumberController,
                            decoration: const InputDecoration(labelText: 'Amazon PO Number', border: OutlineInputBorder()),
                            validator: (val) => val!.isEmpty ? 'Required' : null,
                          ),
                          DropdownButtonFormField<String>(
                            value: selectedVendor,
                            items: vendors.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                            decoration: const InputDecoration(labelText: 'Vendor', border: OutlineInputBorder()),
                            onChanged: (value) {
                              setState(() {
                                selectedVendor = value;
                              });
                              updateBNBPO(); // Manually trigger in case dropdown doesn't update controller immediately
                            },
                            validator: (val) => val == null ? 'Required' : null,
                          ),
                          TextFormField(
                            controller: bnbPoNumberController,
                            decoration: const InputDecoration(labelText: 'BNB PO Number', border: OutlineInputBorder()),
                            validator: (val) => val!.isEmpty ? 'Required' : null,
                          ),
                          DropdownButtonFormField<String>(
                            value: selectedLocation,
                            items: locations.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                            decoration: const InputDecoration(labelText: 'Delivery Location', border: OutlineInputBorder()),
                            onChanged: (val) => setState(() => selectedLocation = val),
                            validator: (val) => val == null ? 'Required' : null,
                          ),
                          TextFormField(
                            controller: asnController,
                            decoration: const InputDecoration(labelText: 'ASN', border: OutlineInputBorder()),
                          ),
                          TextFormField(
                            controller: appointmentIdController,
                            decoration: const InputDecoration(labelText: 'Appointment ID', border: OutlineInputBorder()),
                          ),
                          ListTile(
                            title: Text(appointmentDate == null ? "Select Appointment Date" :
                            DateFormat('yyyy-MM-dd – hh:mm a').format(appointmentDate!)),
                            trailing: const Icon(Icons.calendar_today),
                            onTap: selectAppointmentDate,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Right File Upload Section
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () => pickFile('appointment'),
                          child: Container(
                            height: 100,
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: appointmentFile == null
                                  ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add, size: 28, color: Colors.blue),
                                  SizedBox(height: 4),
                                  Text('Appointment Letter'),
                                ],
                              )
                                  : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.insert_drive_file, size: 28, color: Colors.green),
                                  const SizedBox(height: 4),
                                  Text(appointmentFile!.name, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => pickFile('bnb'),
                          child: Container(
                            height: 100,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: bnbInvoiceFile == null
                                  ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add, size: 28, color: Colors.blue),
                                  SizedBox(height: 4),
                                  Text('BNB Invoice'),
                                ],
                              )
                                  : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.insert_drive_file, size: 28, color: Colors.green),
                                  const SizedBox(height: 4),
                                  Text(bnbInvoiceFile!.name, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text("Product Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),

              DataTable(
                columns: const [
                  DataColumn(label: Text("S.No")),
                  DataColumn(label: Text("ASIN")),
                  DataColumn(label: Text("Barcode")),
                  DataColumn(label: Text("Title")),
                  DataColumn(label: Text("Requested")),
                  DataColumn(label: Text("Confirmed")),
                  DataColumn(label: Text("Unit Cost")),
                  DataColumn(label: Text("Total")),
                  DataColumn(label: Text("")),
                ],
                rows: [
                  // Filled rows
                  ...productDetails.asMap().entries.map((entry) {
                    final index = entry.key; // ✅ Use the real index
                    final item = entry.value;
                    return DataRow(cells: [
                      DataCell(Text((index + 1).toString())), // Show 1-based display only here
                      DataCell(Text(item['asin'] ?? '')),
                      DataCell(Text(item['barcode'] ?? '')),
                      DataCell(Text(item['title'] ?? '')),
                      DataCell(Text(item['requested'] ?? '')),
                      DataCell(Text(item['confirmed'] ?? '')),
                      DataCell(Text(item['unitCost'] ?? '')),
                      DataCell(Text(item['total'] ?? '')),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () => deleteProductRow(index), // ✅ Use correct index
                        ),
                      ),
                    ]);
                  }).toList(),
                  // Input row
                  DataRow(
                    cells: [
                      DataCell(Text((productDetails.length + 1).toString())),
                      DataCell(
                          CompositedTransformTarget(
                            link: _layerLink,
                            child: TextField(
                              controller: asinController,
                              decoration: const InputDecoration(border: InputBorder.none),
                              onChanged: searchProducts,
                            ),
                          )
                      ),
                      DataCell(
                          CompositedTransformTarget(
                              link: _layerLink,
                              child: TextField(controller: barcodeController, decoration: const InputDecoration(border: InputBorder.none),onChanged: searchProducts,))),
                      DataCell(
                          CompositedTransformTarget(
                              link: _layerLink,
                          child: TextField(controller: titleController, maxLines: 3,decoration: const InputDecoration(border: InputBorder.none),onChanged: searchProducts,))),
                      DataCell(TextField(controller: requestedUnitsController, keyboardType: TextInputType.number, decoration: const InputDecoration(border: InputBorder.none))),
                      DataCell(TextField(controller: confirmedDetailsController, keyboardType: TextInputType.number, decoration: const InputDecoration(border: InputBorder.none))),
                      DataCell(TextField(controller: unitCostController, keyboardType: TextInputType.number, decoration: const InputDecoration(border: InputBorder.none))),
                      DataCell(Text(
                        calculateTotal().toStringAsFixed(2),
                      )),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.green),
                          onPressed: addProductRow,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(
                height: 30,
              ),
              Center(
                child: ElevatedButton(
                  onPressed: isLoading ? null : submitOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black, // Button background color
                    foregroundColor: Colors.white, // Text & icon color
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Submit Order"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
