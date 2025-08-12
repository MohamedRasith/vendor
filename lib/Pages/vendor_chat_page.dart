import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
  String? _status;

  Uint8List? _selectedFileBytes;
  String? _selectedFileName;

  Future<void> pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'jpg', 'png'],
      withData: true, // important for web to get bytes
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _selectedFileBytes = result.files.single.bytes;
        _selectedFileName = result.files.single.name;
        _messageController.text = result.files.single.name;
      });
    }
  }


  Stream<QuerySnapshot> getMessages() {
    return FirebaseFirestore.instance
        .collection('tickets')
        .doc(widget.ticketId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots();
  }

  Future<void> sendMessage() async {
    if (_messageController.text.trim().isEmpty && _selectedFileBytes == null) return;

    setState(() => _isSending = true);

    String? fileUrl;
    try {
      // If file is selected, upload to Firebase Storage
      if (_selectedFileBytes != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('ticket_attachments/${widget.ticketId}/${DateTime.now().millisecondsSinceEpoch}_$_selectedFileName');

        await storageRef.putData(_selectedFileBytes!);
        fileUrl = await storageRef.getDownloadURL();
      }


      await FirebaseFirestore.instance
          .collection('tickets')
          .doc(widget.ticketId)
          .collection('messages')
          .add({
        'message': _messageController.text.trim(),
        'fileUrl': fileUrl, // null if no file
        'fileName': _selectedFileName,
        'sender': 'vendor',
        'timestamp': Timestamp.now(),
      });

      _messageController.clear();
      _selectedFileBytes = null;
      _selectedFileName = null;
    } catch (e) {
      print("Send message error: $e");
    } finally {
      setState(() => _isSending = false);
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
    } else {
      setState(() {
        _status = 'pending';
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
      Navigator.pop(context);
    });
  }


  @override
  Widget build(BuildContext context) {
    if (_status == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text("Chat - ${widget.ticketTitle}", style: TextStyle(color: Colors.white)),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Chat - ${widget.ticketTitle}", style: TextStyle(color: Colors.white)),
            Text("Status: ${_status}", style: TextStyle(fontSize: 12, color: Colors.white70)),
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
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment:
                        isVendor ? MainAxisAlignment.end : MainAxisAlignment.start,
                        children: [
                          // Constrain the bubble width (max 70% of screen width)
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.7,
                            ),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isVendor ? Colors.green[200] : Colors.grey[300],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (doc['message'] != null && doc['message'].isNotEmpty)
                                    Text(doc['message']),
                                  if (doc['fileUrl'] != null && (doc['fileUrl'] as String).isNotEmpty)
                                    InkWell(
                                      onTap: () => launchUrl(Uri.parse(doc['fileUrl'])),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.insert_drive_file, color: Colors.blue),
                                          SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              doc['fileName'] ?? 'Attachment',
                                              style: TextStyle(color: Colors.blue),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          Divider(height: 1),
          if (_status != "closed")
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.attach_file),
                    onPressed: pickDocument,
                  ),
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
      floatingActionButton: _status == "closed"
          ? null
          : Align(
        alignment: Alignment.bottomRight,
        child: Container(
          margin: const EdgeInsets.only(right: 16, bottom: 50),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => updateStatus('closed'),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.close, color: Colors.white),
                Text(
                  "Mark as Closed",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
