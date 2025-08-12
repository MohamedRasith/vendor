import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class VendorReportsPage extends StatelessWidget {
  final String loggedInVendorName; // You pass this from login/session

  const VendorReportsPage({Key? key, required this.loggedInVendorName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text('My Reports', style: TextStyle(color: Colors.white),)),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .where('vendor', isEqualTo: loggedInVendorName)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No reports found.'));
          }

          final reports = snapshot.data!.docs;

          return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    columnSpacing: 20,
                    headingRowColor: MaterialStateColor.resolveWith(
                          (states) => Colors.grey.shade200,
                    ),
                    columns: const [
                      DataColumn(label: Text("Type", style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text("Amount", style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text("Date", style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text("Attachment", style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: reports.map((report) {
                      final type = report['reportType'] ?? '';
                      final amount = report['amount']?.toString() ?? '';
                      final attachment = report['attachment'] ?? '';
                      final timestamp = report['timestamp']?.toDate();
                      final dateStr = timestamp != null
                          ? DateFormat('dd MMM yyyy').format(timestamp)
                          : '';

                      DataCell copyCell(String text, {TextStyle? style}) {
                        return DataCell(
                          Text(text, style: style),
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: text));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('"$text" copied')),
                            );
                          },
                        );
                      }

                      return DataRow(
                        cells: [
                          copyCell(type),
                          copyCell("AED $amount"),
                          copyCell(dateStr),
                          DataCell(
                            attachment.isNotEmpty
                                ? ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {
                                launchUrl(Uri.parse(attachment));
                              },
                              icon: const Icon(Icons.attach_file, color: Colors.white, size: 20),
                              label: const Text(
                                'View Attachment',
                                style: TextStyle(color: Colors.white),
                              ),
                            )
                                : const Text('-'),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
