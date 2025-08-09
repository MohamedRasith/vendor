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
        .collection('vendorTickets')
        .where('vendorName', isEqualTo: widget.vendorName)
        .orderBy('createdAt', descending: true)
        .get();

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

    await FirebaseFirestore.instance.collection('vendorTickets').add(data);

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
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Query Title'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: InputDecoration(labelText: 'Description'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: submitQuery,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              child: Text("Submit Query"),
            ),
            SizedBox(height: 30),
            Divider(),
            Text("Your Previous Queries", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            if (myQueries.isEmpty)
              Text("No queries submitted yet.", style: TextStyle(color: Colors.grey))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: myQueries.length,
                itemBuilder: (context, index) {
                  final query = myQueries[index];
                  return Card(
                    child: ListTile(
                      title: Text(query['title']),
                      subtitle: Text(query['description']),
                      trailing: Text(
                        query['status'].toString().toUpperCase(),
                        style: TextStyle(
                          color: query['status'] == 'open'
                              ? Colors.green
                              : query['status'] == 'closed'
                              ? Colors.orange
                              : Colors.red,
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
