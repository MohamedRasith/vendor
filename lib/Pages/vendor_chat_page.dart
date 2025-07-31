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
  String _status = 'pending';


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
  void initState() {
    super.initState();
    fetchTicketStatus();
  }

  void fetchTicketStatus() async {
    final doc = await FirebaseFirestore.instance
        .collection('tickets')
        .doc(widget.ticketId)
        .get();

    if (doc.exists && doc.data() != null) {
      setState(() {
        _status = doc['status'] ?? 'pending';
      });
    }
  }
  Future<void> updateStatus(String newStatus) async {
    await FirebaseFirestore.instance
        .collection('tickets')
        .doc(widget.ticketId)
        .update({'status': newStatus});

    setState(() {
      _status = newStatus;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Chat - ${widget.ticketTitle}", style: TextStyle(color: Colors.white)),
            Text("Status: ${_status.toUpperCase() == "OPEN"?"Pending":_status}", style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
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
      floatingActionButton: Align(
        alignment: Alignment.bottomRight,
        child: Container(
          margin: const EdgeInsets.only(right: 16, bottom: 45),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              popupMenuTheme: PopupMenuThemeData(
                color: Colors.black,
                textStyle: TextStyle(color: Colors.white),
              ),
            ),
            child: PopupMenuButton<String>(
              offset: Offset(0, -100), // show menu upward
              color: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              onSelected: (value) => updateStatus(value),
              itemBuilder: (context) => [
                if (_status != 'on process')
                  PopupMenuItem(
                    value: 'on process',
                    child: Text('Mark as On Process', style: TextStyle(color: Colors.white)),
                  ),
                if (_status != 'completed')
                  PopupMenuItem(
                    value: 'completed',
                    child: Text('Mark as Completed', style: TextStyle(color: Colors.white)),
                  ),
              ],
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.settings, color: Colors.white),
                  Text(
                    "Click here\nto update status",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),


    );
  }
}
