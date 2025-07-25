import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class VendorChatPage extends StatefulWidget {
  final String ticketId;
  final String ticketTitle;

  VendorChatPage({required this.ticketId, required this.ticketTitle});

  @override
  _VendorChatPageState createState() => _VendorChatPageState();
}

class _VendorChatPageState extends State<VendorChatPage> {
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;


  Stream<QuerySnapshot> getMessages() {
    return FirebaseFirestore.instance
        .collection('tickets')
        .doc(widget.ticketId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots();
  }

  Future<void> sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    setState(() => _isSending = true); // Start loading

    try {
      await FirebaseFirestore.instance
          .collection('tickets')
          .doc(widget.ticketId)
          .collection('messages')
          .add({
        'message': _messageController.text.trim(),
        'sender': 'vendor',
        'timestamp': Timestamp.now(),
      });

      _messageController.clear();
    } catch (e) {
      print("Send message error: $e");
    } finally {
      setState(() => _isSending = false); // Stop loading
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: IconThemeData(color: Colors.white),
          title: Text("Chat - ${widget.ticketTitle}", style: TextStyle(color: Colors.white),)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getMessages(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                final messages = snapshot.data!.docs;

                return ListView(
                  padding: EdgeInsets.all(8),
                  children: messages.map((doc) {
                    final isVendor = doc['sender'] == 'vendor';
                    return Align(
                      alignment: isVendor ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        margin: EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: isVendor ? Colors.green[200] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(doc['message']),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          Divider(height: 1),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(hintText: "Type a reply..."),
                  ),
                ),
                _isSending
                    ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
                    : IconButton(
                  icon: Icon(Icons.send),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
