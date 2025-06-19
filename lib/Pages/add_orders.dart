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
  DateTime? appointmentDate;

  String? selectedVendor;
  String? selectedLocation;
  bool isLoading = false;

  List<String> vendors = ["Vendor A", "Vendor B", "Vendor C"];
  List<String> locations = ["Dubai", "Abu Dhabi", "Sharjah"];

  @override
  void initState() {
    super.initState();
    fetchVendors();
  }

  void updateBNBPO() {
    final amazonPO = poNumberController.text.trim();
    final vendor = selectedVendor ?? "";
    if (amazonPO.isNotEmpty && vendor.isNotEmpty) {
      bnbPoNumberController.text = "$amazonPO-$vendor";
    }
  }

  Future<void> fetchVendors() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    setState(() {
      vendors = snapshot.docs.map((doc) => doc['fullName'] as String).toList();
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Orders"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
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
                  ElevatedButton(
                    onPressed: isLoading ? null : submitOrder,
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Submit Order"),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),
            // const Divider(),
            // const Text("Orders List", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            // const SizedBox(height: 8),
            // Expanded(
            //   child: StreamBuilder(
            //     stream: FirebaseFirestore.instance.collection('orders').orderBy('createdAt', descending: true).snapshots(),
            //     builder: (context, snapshot) {
            //       if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            //       final docs = snapshot.data!.docs;
            //       return ListView.builder(
            //         itemCount: docs.length,
            //         itemBuilder: (context, index) {
            //           final data = docs[index];
            //           return ListTile(
            //             title: Text(data['amazonPONumber'] ?? ''),
            //             subtitle: Text("Vendor: ${data['vendor']}, Location: ${data['location']}"),
            //           );
            //         },
            //       );
            //     },
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
