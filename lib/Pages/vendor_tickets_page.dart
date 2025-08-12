import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

        return SingleChildScrollView(
          child: DataTable(
            columnSpacing: 20,
            headingRowColor: MaterialStateColor.resolveWith(
                  (states) => Colors.grey.shade200,
            ),
            columns: const [
              DataColumn(label: Text("Ticket ID", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("Title", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("Description", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("Created At", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("Status", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("Chat", style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: tickets.map((ticket) {
              final ticketId = ticket.id;
              final title = ticket['title'] ?? '';
              final description = ticket['description'] ?? '';
              final createdAt = DateFormat('dd MMM yyyy, hh:mm a')
                  .format(ticket['createdAt'].toDate());
              final status = ticket['status'] ?? '';

              // Helper for clickable cell with copy
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
                  copyCell(ticketId),
                  copyCell(title),
                  copyCell(description),
                  copyCell(createdAt),
                  copyCell(
                    status,
                    style: TextStyle(
                      color: status == "open" ? Colors.green : Colors.red,
                    ),
                  ),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.chat, color: Colors.blue),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VendorChatPage(
                              ticketId: ticketId,
                              ticketTitle: title,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
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
