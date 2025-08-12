import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CreateQueryWithAdmin extends StatefulWidget {
  final String vendorName;

  CreateQueryWithAdmin({required this.vendorName});

  @override
  _CreateQueryWithAdminState createState() => _CreateQueryWithAdminState();
}

class _CreateQueryWithAdminState extends State<CreateQueryWithAdmin> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  List<DocumentSnapshot> myQueries = [];

  @override
  void initState() {
    super.initState();
    fetchMyQueries();
  }

  Future<void> fetchMyQueries() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('tickets')
        .where('vendorName', isEqualTo: widget.vendorName)
        .orderBy('createdAt', descending: true)
        .get();

    print("Fetched queries count: ${snapshot.docs.length}");
    for (var doc in snapshot.docs) {
      print("Doc data: ${doc.data()}");
    }

    setState(() {
      myQueries = snapshot.docs;
    });
  }

  Future<void> submitQuery() async {
    if (_titleController.text.trim().isEmpty || _descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    final data = {
      'title': _titleController.text.trim(),
      'description': _descController.text.trim(),
      'vendorName': widget.vendorName,
      'createdAt': Timestamp.now(),
      'status': 'open',
    };

    await FirebaseFirestore.instance.collection('tickets').add(data);

    _titleController.clear();
    _descController.clear();

    fetchMyQueries();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Query submitted")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Raise Query to Admin"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Table header row (titles only)
                ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: Table(
                    border: TableBorder.all(color: Colors.grey),
                    columnWidths: {
                      0: FixedColumnWidth(200),
                      1: FixedColumnWidth(400),
                      2: FixedColumnWidth(120),
                    },
                    children: [
                      TableRow(
                        decoration: BoxDecoration(color: Colors.grey.shade300),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text("Title", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text("Description", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text("Action",textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Input fields + submit button row inside a Table
                ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: Table(
                    border: TableBorder.all(color: Colors.grey),
                    columnWidths: {
                      0: FixedColumnWidth(200),
                      1: FixedColumnWidth(400),
                      2: FixedColumnWidth(120),
                    },
                    children: [
                      TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextField(
                              controller: _titleController,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                isDense: true,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextField(
                              controller: _descController,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                isDense: true,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextButton(
                              onPressed: submitQuery,
                              child: Text("Submit"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 30),

                // Data rows for previous queries
                Table(
                  border: TableBorder.all(color: Colors.grey),
                  columnWidths: {
                    0: FixedColumnWidth(200),
                    1: FixedColumnWidth(400),
                    2: FixedColumnWidth(100),
                    3: FixedColumnWidth(120),
                  },
                  children: [
                    // Header row
                    TableRow(
                      decoration: BoxDecoration(color: Colors.grey.shade300),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            'Title',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            'Description',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            'Status',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            'Created At',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    // Data rows
                    ...myQueries.map((query) {
                      final data = query.data() as Map<String, dynamic>?;

                      final title = data?['title'] ?? '';
                      final description = data?['description'] ?? '';
                      final status = data?['status'] ?? '';
                      final createdAtTimestamp = data?['createdAt'] as Timestamp?;
                      final createdAtStr = createdAtTimestamp != null
                          ? "${createdAtTimestamp.toDate().day}/${createdAtTimestamp.toDate().month}/${createdAtTimestamp.toDate().year}"
                          : '';

                      Color statusColor;
                      if (status == 'open') {
                        statusColor = Colors.green;
                      } else if (status == 'closed') {
                        statusColor = Colors.orange;
                      } else {
                        statusColor = Colors.red;
                      }

                      return TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(title),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              description,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(color: statusColor),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(createdAtStr),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                )
              ],
            ),
          );
        }
      ),
    );
  }
}
