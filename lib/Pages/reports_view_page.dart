import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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

          return ListView.builder(
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              final type = report['reportType'];
              final amount = report['amount'];
              final attachment = report['attachment'];
              final timestamp = report['timestamp']?.toDate();

              return Card(
                color: Colors.white,
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  title: Text('$type Report'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Amount: AED $amount'),
                      if (timestamp != null)
                        Text('Date: ${timestamp.toLocal().toString().split(' ')[0]}'),
                      RawMaterialButton(
                        onPressed: () {
                          launchUrl(Uri.parse(attachment));
                        },
                        fillColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.attach_file, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'View Attachment',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
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
