import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:vendor/Pages/vendor_chat_page.dart';
import 'package:vendor/Pages/create_query_with_admin.dart';

class VendorTicketList extends StatelessWidget {
  final String vendorName;

  VendorTicketList({required this.vendorName});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Two tabs: Open & Closed
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text('Vendor Tickets', style: TextStyle(color: Colors.white)),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,           // Selected tab text color
            unselectedLabelColor: Colors.white, // Unselected tab text color
            tabs: [
              Tab(text: "Open Tickets"),
              Tab(text: "Closed Tickets"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Open Tickets
            ticketListTab(vendorName, "open"),
            // Closed Tickets
            ticketListTab(vendorName, "closed"),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CreateQueryWithAdmin(vendorName: vendorName),
              ),
            );
          },
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          icon: Icon(Icons.add),
          label: Text("Raise a Query"),
        ),
      ),
    );
  }

  Widget ticketListTab(String vendorName, String statusFilter) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tickets')
          .where('vendorName', isEqualTo: vendorName)
          .where('status', isEqualTo: statusFilter)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final tickets = snapshot.data!.docs;

        if (tickets.isEmpty) {
          return Center(child: Text("No $statusFilter tickets found."));
        }

        return ListView.builder(
          itemCount: tickets.length,
          itemBuilder: (context, index) {
            final ticket = tickets[index];
            return Card(
              color: Colors.white,
              child: ListTile(
                title: Text(ticket['title']),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    richText("Ticket ID:", ticket.id),
                    const SizedBox(height: 10),
                    richText("Description:", ticket['description'] ?? ''),
                    const SizedBox(height: 10),
                    richText(
                      "Created at:",
                      DateFormat('dd MMM yyyy, hh:mm a')
                          .format(ticket['createdAt'].toDate()),
                    ),
                    const SizedBox(height: 10),
                    richText(
                      "Status:",
                      ticket['status'],
                      valueColor: ticket['status'] == "open"
                          ? Colors.green
                          : Colors.red,
                    ),
                  ],
                ),
                trailing: Icon(Icons.chat),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VendorChatPage(
                        ticketId: ticket.id,
                        ticketTitle: ticket['title'],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget richText(String label, String value, {Color? valueColor}) {
    return RichText(
      text: TextSpan(
        text: "$label\n",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black,
          fontFamily: GoogleFonts.poppins().fontFamily,
        ),
        children: [
          TextSpan(
            text: value,
            style: TextStyle(
              fontWeight: FontWeight.normal,
              color: valueColor ?? Colors.black,
              fontFamily: GoogleFonts.poppins().fontFamily,
            ),
          ),
        ],
      ),
    );
  }
}
