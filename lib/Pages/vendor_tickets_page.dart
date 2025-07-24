import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:vendor/Pages/vendor_chat_page.dart';

class VendorTicketList extends StatelessWidget {
  final String vendorName; // Pass vendorId here

  VendorTicketList({required this.vendorName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text('Vendor Tickets', style: TextStyle(color: Colors.white),)),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tickets')
            .where('vendorName', isEqualTo: vendorName)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final tickets = snapshot.data!.docs;

          if (tickets.isEmpty) {
            return Center(child: Text("No tickets assigned to you."));
          }

          return ListView.builder(
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              return Card(
                color: Colors.white,
                child: ListTile(
                  title: Text(ticket['title']),
                  subtitle: Text(ticket['description']),
                  trailing: Icon(Icons.chat),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => VendorChatPage(
                        ticketId: ticket.id,
                        ticketTitle: ticket['title'],
                      ),
                    ));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
