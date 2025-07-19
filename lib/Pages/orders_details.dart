import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:url_launcher/url_launcher.dart';
import 'dart:html' as html;

import 'package:vendor/widgets/expiry_date_formatter.dart';

class OrderDetailsPage extends StatefulWidget {
  final QueryDocumentSnapshot order;
  const OrderDetailsPage({super.key, required this.order});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  late List<Map<String, dynamic>> products;
  var total;
  late TextEditingController appointmentIdController;
  late TextEditingController asnController;
  late TextEditingController bnbPONumberController;
  late TextEditingController locationController;
  late TextEditingController vendorController;
  late TextEditingController boxesController;

  DateTime? appointmentDate;
  int totalBoxCount = 0;

  @override
  void initState() {
    super.initState();
    final data = widget.order.data() as Map<String, dynamic>;

    appointmentIdController = TextEditingController(text: data['appointmentId'] ?? '');
    asnController = TextEditingController(text: data['asn'] ?? '');
    bnbPONumberController = TextEditingController(text: data['bnbPONumber'] ?? '');
    locationController = TextEditingController(text: data['location'] ?? '');
    vendorController = TextEditingController(text: data['vendor'] ?? '');
    appointmentDate = data['appointmentDate']?.toDate();
    boxesController = TextEditingController(text: data['boxCount']?.toString() ?? '');

    products = (data['products'] as List<dynamic>).map((e) => Map<String, dynamic>.from(e)).toList();


    for (var product in products) {
      if (product['confirmed'] == null || product['confirmed'].toString().isEmpty) {
        product['confirmed'] = 0;
        product['batchNo'] ??= '';
        product['expiryDate'] ??= '';
      }
    }
    fetchVendorDetails(widget.order['vendor']);

  }

  Future<Map<String, dynamic>> fetchVendorDetails(String vendorName) async {
    final query = await FirebaseFirestore.instance
        .collection('vendors')
        .where('vendorName', isEqualTo: vendorName)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return query.docs.first.data();
    } else {
      return {}; // return empty if not found
    }
  }

  String insertLineBreaks(String text, int interval) {
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i + 1) % interval == 0 && i != text.length - 1) {
        buffer.write('\n');
      }
    }
    return buffer.toString();
  }

  Future<void> generatePdf(var products, var order) async {
    final pdf = pw.Document();

    final logoBytes = await rootBundle.load('assets/images/buybill.png').then((value) => value.buffer.asUint8List());
    final logoImage = pw.MemoryImage(logoBytes);

    final tableHeaders = ['', 'Product', 'Cost', 'QTY', 'Total'];

    final todayDate = DateFormat('dd MMM, yyyy').format(DateTime.now());

    final double subtotal = products.fold(0.0, (sum, item) {
      final value = item['total'];
      if (value is num) return sum + value;
      if (value is String) return sum + double.tryParse(value) ?? 0.0;
      return sum;
    });

    final double vat = subtotal * 0.05;
    final double grandTotal = subtotal + vat;

    final vendorName = widget.order['vendor'];
    final vendorData = await fetchVendorDetails(vendorName);

    final companyName = vendorData['companyName'] ?? 'Buy and bill LLC';
    final address1 = vendorData['addressLine1'] ?? 'Sharjah Media City';
    final address2 = vendorData['addressLine2'] ?? 'Sharjah UAE';
    final phone = vendorData['contactPersonNumber'] ?? '+971 52 603 3484';


    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(10), // Reduce margin (default is 40)
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.start,
        build: (context) => [
          pw.Center(
            child:pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                // Logo on the left
                pw.Container(
                  height: 100,
                  width: 150,
                  child: pw.Image(
                      logoImage
                  ),
                ),

                // Title on the right
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'BUY AND BILL LLC',
                      style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'PURCHASE ORDER',
                      style: pw.TextStyle(fontSize: 18),
                    ),
                    pw.SizedBox(height: 10),
                    pw.BarcodeWidget(
                      data: widget.order['amazonPONumber'] ?? '',
                      barcode: pw.Barcode.code128(), // Code128 supports alphanumeric
                      width: 200,
                      height: 60,
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('$vendorName,'),
                  pw.Text('$address1,'),
                  pw.Text('$address2.'),
                  pw.Text(phone),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('DATE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(todayDate),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey), // Header border
            children: [
              pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.black),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('P/O NUMBER', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Deliver To', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('TERMS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                    ),
                  ]),
              pw.TableRow(children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(widget.order['amazonPONumber'] ?? ''),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(widget.order['location'] ?? 'Not set'),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('NET 60 Days'),
                ),
              ]),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Table(
            columnWidths: {
              0: const pw.FixedColumnWidth(30), // Serial No. column
              1: const pw.FixedColumnWidth(180), // Product column
              2: const pw.FixedColumnWidth(30),  // Cost column
              3: const pw.FixedColumnWidth(30),  // Quantity Requested column
              4: const pw.FixedColumnWidth(50),  // Total column
            },
            border: pw.TableBorder.all(color: PdfColors.grey), // Body border
            children: [
              // Header row with black background and white borders
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.black),
                children: tableHeaders.map((header) {
                  return pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        left: pw.BorderSide(color: PdfColors.white, width: 1),
                        right: pw.BorderSide(color: PdfColors.white, width: 1),
                      ),
                    ),
                    child: pw.Text(
                      header,
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  );
                }).toList(),
              ),

              // Data rows
              ...products.asMap().entries.map((entry) {
                final index = entry.key;     // Serial number = index + 1
                final p = entry.value;

                final title = p['title'] as String;
                final truncatedTitle = title.length > 100 ? '${title.substring(0, 100)}...' : title;

                final description = '$truncatedTitle\nBARCODE: ${p['barcode']}\nASIN: ${p['asin']}';


                return pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text((index + 1).toString()),  // S. No.
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(description),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(p['unitCost'].toString()),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(p['requested'].toString()),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(p['total'].toString()),
                    ),
                  ],
                );
              }).toList(),
            ],
          ),

          pw.SizedBox(height: 30),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              width: 200,
              child: pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Subtotal'),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('AED ${subtotal.round()}'),
                    ),
                  ]),
                  pw.TableRow(children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('VAT 5%'),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('AED ${vat.round()}'),
                    ),
                  ]),
                  pw.TableRow(children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('TOTAL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('AED ${grandTotal.round()}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'purchase_order.pdf');
  }

  Future<void> deliveryNote(var products, var order) async {
    final pdf = pw.Document();

    // Load logo image
    final logoBytes = await rootBundle.load('assets/images/buybill.png');
    final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

    final todayDate = DateFormat('dd MMM, yyyy').format(DateTime.now());

    // Fetch vendor details
    final vendorName = order['vendor'];
    final vendorData = await fetchVendorDetails(vendorName);

    final companyName = vendorData['companyName'] ?? '[Company Name]';
    final address1 = vendorData['addressLine1'] ?? '[Street Address]';
    final address2 = vendorData['addressLine2'] ?? '[City, ST ZIP Code]';
    final phone = vendorData['contactPersonNumber'] ?? '[Phone]';

    final int totalConfirmed = products.fold(0, (sum, p) {
      final confirmed = p['confirmed'];
      if (confirmed is int) return sum + confirmed;
      if (confirmed is double) return sum + confirmed.toInt();
      if (confirmed is String) return sum + int.tryParse(confirmed) ?? 0;
      return sum;
    });

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(16),
        build: (context) => [
          // Header
          pw.Center(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Image(logoImage, width: 200),
                    pw.SizedBox(height: 8),
                    pw.Column(
                      children: [
                        pw.Text('BUY AND BILL LLC', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Delivery Note', style: pw.TextStyle(fontSize: 18)),
                        pw.BarcodeWidget(
                          data: widget.order['appointmentId'] ?? '',
                          barcode: pw.Barcode.code128(), // Code128 supports alphanumeric
                          width: 200,
                          height: 60,
                        ),
                      ]
                    )
                  ]
                )

              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Info table: Seller / Buyer / ASN Details
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.black),
            columnWidths: {
              0: pw.FlexColumnWidth(2),
              1: pw.FlexColumnWidth(2),
              2: pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                pw.Container(padding: const pw.EdgeInsets.all(4), child: pw.Text('Seller', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Container(padding: const pw.EdgeInsets.all(4), child: pw.Text('Buyer', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Container(padding: const pw.EdgeInsets.all(4), child: pw.Text('ASN', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
              ]),
              pw.TableRow(children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Text('BUY AND BILL LLC'),
                    pw.Text('10th Level 1, Sharjah Media City'),
                    pw.Text('Sharjah UAE'),
                    pw.Text('TRN: 10404110400003'),
                    pw.Text('Contact: +971 554306574'),
                    pw.Text('email: info@buybill.com'),
                  ]),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Text('Q Tech General Trading LLC'),
                    pw.Text('IBN Battuta Gate office 602,\nThe Gardens,'),
                    pw.Text('Dubai, United Arab Emirates, 54107'),
                    pw.Text('VAT : 100483307300003'),
                  ]),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Text('Appointment ID: ${order['appointmentId'] ?? ''}'),
                    pw.Text('Delivery Location: ${order['location'] ?? ''}'),
                    pw.Text('Invoice No.: ${order['invoiceNo'] ?? ''}'),
                    pw.Text('Delivery Date: $todayDate'),
                  ]),
                ),
              ]),
            ],
          ),

          pw.SizedBox(height: 12),

          // PO Info Row
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.black),
            columnWidths: {
              0: pw.FlexColumnWidth(2),
              1: pw.FlexColumnWidth(1),
              2: pw.FlexColumnWidth(2),
              3: pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('P/O NUMBER', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('No. of Boxes', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Deliver To', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('TERMS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                ],
              ),
              pw.TableRow(children: [
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(order['amazonPONumber'] ?? '')),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(order['boxCount']?.toString() ?? '')),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(order['location'] ?? '')),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('NET 60 Days')),
              ]),
            ],
          ),

          pw.SizedBox(height: 12),

          // Product Header Row
          // Product Table
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey),
            columnWidths: {
              0: pw.FlexColumnWidth(0.3), // S. No
              1: pw.FlexColumnWidth(3),   // Product
              2: pw.FlexColumnWidth(1),   // Quantity Confirmed
            },
            children: [
              // Header Row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'S. No',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'Product',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'Quantity Confirmed',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                ],
              ),

              // Product Rows with index
              ...products.asMap().entries.map((entry) {
                final index = entry.key;
                final p = entry.value;

                final title = p['title'] ?? '';
                final barcode = p['barcode'] ?? '';
                final asin = p['asin'] ?? '';
                final qty = p['confirmed']?.toString() ?? '0';

                return pw.TableRow(
                  children: [
                    pw.Center(
                      child:  pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text((index + 1).toString()),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        '$title\nBARCODE: $barcode\nASIN: $asin',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ),
                    pw.Center(
                      child: pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(qty),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ],
          ),


          pw.SizedBox(height: 30),

          // Footer
          pw.Center(
            child: pw.Text(
              'Total Confirmed Units: $totalConfirmed',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'delivery_note.pdf');
  }


  Future<void> uploadToAmazon() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (result == null || result.files.isEmpty) {
      // User canceled or no file selected
      return;
    }

    final file = result.files.first;
    final fileBytes = file.bytes;
    final fileName = file.name;

    if (fileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to read file.")),
      );
      return;
    }

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('upload_to_amazon_files/${widget.order.id}/$fileName');

      // Upload file bytes
      final uploadTask = await storageRef.putData(fileBytes);

      // Get download URL
      final downloadUrl = await storageRef.getDownloadURL();

      // Save download URL to Firestore order document
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.order.id)
          .update({'uploadToAmazon': downloadUrl, 'status': 'Completed'});

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("File uploaded and link saved successfully.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: $e")),
      );
    }
  }

  Future<void> exportOrderToExcel(List products, var order) async {
    final workbook = xlsio.Workbook();
    final sheet = workbook.worksheets[0];
    sheet.name = 'Purchase Order';

    final today = DateTime.now();
    final dateStr = '${today.day}/${today.month}/${today.year}';

    // Title
    sheet.getRangeByName('A1').setText('BUY AND BILL LLC');
    sheet.getRangeByName('A2').setText('PURCHASE ORDER');
    sheet.getRangeByName('F1').setText('Date');
    sheet.getRangeByName('G1').setText(dateStr);
    sheet.getRangeByName('A4').setText('Vendor: ${order['vendor'] ?? 'Not set'}');
    sheet.getRangeByName('F4').setText('P/O No: ${order['amazonPONumber'] ?? ''}');
    sheet.getRangeByName('F5').setText('Location: ${order['location'] ?? 'Not set'}');
    sheet.getRangeByName('F6').setText('Terms: NET 60 Days');

    // Table Header
    final headers = ['S.No', 'Product', 'Cost', 'Qty Requested', 'Qty Confirmed', 'Total'];
    for (int i = 0; i < headers.length; i++) {
      sheet.getRangeByIndex(8, i + 1).setText(headers[i]);
      sheet.getRangeByIndex(8, i + 1).cellStyle.bold = true;
    }

    // Table Rows
    double subtotal = 0.0;
    for (int i = 0; i < products.length; i++) {
      final p = products[i];
      final title = p['title'] ?? '';
      final barcode = p['barcode'] ?? '';
      final asin = p['asin'] ?? '';
      final unitCost = p['unitCost']?.toString() ?? '0';
      final requested = p['requested']?.toString() ?? '0';
      final confirmed = p['confirmed']?.toString() ?? '0';
      final total = (p['total'] is String)
          ? double.tryParse(p['total']) ?? 0
          : (p['total'] is num)
          ? p['total'].toDouble()
          : 0.0;

      final desc = '${title.length > 20 ? title.substring(0, 20) + '...' : title}\nBARCODE: $barcode\nASIN: $asin';

      subtotal += total;

      sheet.getRangeByIndex(i + 9, 1).setNumber(i + 1);
      sheet.getRangeByIndex(i + 9, 2).setText(desc);
      sheet.getRangeByIndex(i + 9, 3).setText(unitCost);
      sheet.getRangeByIndex(i + 9, 4).setText(requested);
      sheet.getRangeByIndex(i + 9, 5).setText(confirmed);
      sheet.getRangeByIndex(i + 9, 6).setNumber(total);
    }

    // Totals
    final vat = subtotal * 0.05;
    final grandTotal = subtotal + vat;

    final totalStartRow = products.length + 10;
    sheet.getRangeByIndex(totalStartRow, 5).setText('Subtotal');
    sheet.getRangeByIndex(totalStartRow, 6).setNumber(subtotal);

    sheet.getRangeByIndex(totalStartRow + 1, 5).setText('VAT 5%');
    sheet.getRangeByIndex(totalStartRow + 1, 6).setNumber(vat);

    sheet.getRangeByIndex(totalStartRow + 2, 5).setText('TOTAL');
    sheet.getRangeByIndex(totalStartRow + 2, 6).setNumber(grandTotal);
    sheet.getRangeByIndex(totalStartRow + 2, 5).cellStyle.bold = true;
    sheet.getRangeByIndex(totalStartRow + 2, 6).cellStyle.bold = true;

    // AutoFit columns
    sheet.autoFitColumn(100);

    final List<int> bytes = workbook.saveAsStream();

    final blob = html.Blob([Uint8List.fromList(bytes)], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "PurchaseOrder.xlsx")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  void exportOrderProductsToPDFWeb(List<dynamic> products, var order) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text("Order Products", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Table.fromTextArray(
            headers: [
              'Title',
              'ASIN',
              'Barcode',
              'Requested Qty',
              'Confirmed Qty',
              'Unit Cost',
              'Total Cost',
              'Order ID',
              'Vendor',
            ],
            data: products.map((product) {
              return [
                product['title'] ?? '',
                product['asin'] ?? '',
                product['barcode'] ?? '',
                product['boxCount']?.toString() ?? '',
                product['confirmed']?.toString() ?? '0',
                product['unitCost']?.toString() ?? '',
                product['total']?.toString() ?? '',
                product['orderId']?.toString() ?? '',
                order['vendor'] ?? '',
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 10),
            cellAlignments: {
              0: pw.Alignment.topLeft, // wrap title
            },
            columnWidths: {
              0: const pw.FlexColumnWidth(3), // Title - wider
              1: const pw.IntrinsicColumnWidth(), // ASIN
              2: const pw.IntrinsicColumnWidth(), // Barcode
              3: const pw.FixedColumnWidth(50), // Requested Qty
              4: const pw.FixedColumnWidth(50), // Confirmed Qty
              5: const pw.FixedColumnWidth(50), // Unit Cost
              6: const pw.FixedColumnWidth(50), // Total Cost
              7: const pw.FlexColumnWidth(2), // Order ID
              8: const pw.FlexColumnWidth(2), // Vendor
            },
          ),

        ],
      ),
    );

    final bytes = await pdf.save();

    // Trigger download in web
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'order_products.pdf')
      ..click();
    html.Url.revokeObjectUrl(url);
  }


  Future<void> uploadProofOfDelivery() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final fileBytes = file.bytes;
    final fileName = file.name;

    if (fileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load file.")),
      );
      return;
    }

    try {
      // Upload to Firebase Storage
      final ref = FirebaseStorage.instance.ref().child('proof_of_delivery/$fileName');
      final uploadTask = await ref.putData(fileBytes);
      final fileUrl = await ref.getDownloadURL();

      // Update Firestore order document with file URL
      await FirebaseFirestore.instance.collection('orders').doc(widget.order.id).update({
        'proofOfDeliveryUrl': fileUrl,
        'status' : 'Delivered'
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Proof of Delivery uploaded successfully.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.order.data() as Map<String, dynamic>;
    if (data['appointmentDate'] != null) {
      appointmentDate = (data['appointmentDate'] as Timestamp).toDate();
    } else {
      appointmentDate = null; // or DateTime.now() if you prefer a fallback
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
          backgroundColor: Colors.black,
          title: Text("Order: ${data['amazonPONumber']}", style: TextStyle(color: Colors.white),)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Table(
              border: TableBorder.all(color: Colors.grey), // <-- Add this line
              columnWidths: const {
                0: IntrinsicColumnWidth(),
                1: IntrinsicColumnWidth(),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                // ASN - view only
                TableRow(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text("ASN:", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(data['asn'] ?? ''),
                    ),
                  ],
                ),

// BNB PO Number - view only
                TableRow(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text("BNB PO Number:", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(data['bnbPONumber'] ?? ''),
                    ),
                  ],
                ),

// Appointment ID - view only
                TableRow(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text("Appointment ID:", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(data['appointmentId'] ?? ''),
                    ),
                  ],
                ),

// Appointment Date - view only (keep your InkWell if you want date picking disabled)
                TableRow(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text("Appointment Date & Time:", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        appointmentDate != null
                            ? DateFormat("dd MMM yyyy hh:mm a").format(appointmentDate!)
                            : '',
                      ),
                    ),
                  ],
                ),

// Location - view only
                TableRow(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text("Location:", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(data['location'] ?? ''),
                    ),
                  ],
                ),

// Vendor - view only
                TableRow(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text("Vendor:", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(data['vendor'] ?? ''),
                    ),
                  ],
                ),

// No. of Boxes - Editable
                TableRow(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text("No. of Boxes:", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: boxesController,
                        decoration: const InputDecoration(border: InputBorder.none),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),

              ],
            ),
            const SizedBox(
              height: 20,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => exportOrderToExcel(products, widget.order.data()),
                    icon: const Icon(Icons.file_copy, color: Colors.white,),
                    label: const Text("Export Excel", style: TextStyle(color: Colors.white),),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => generatePdf(products, widget.order.data()),
                    icon: const Icon(Icons.picture_as_pdf, color: Colors.white,),
                    label: const Text("Export PDF", style: TextStyle(color: Colors.white),),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                  const SizedBox(width: 12),
                  widget.order['uploadToAmazon'] != ""?
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: InkWell(
                      onTap: () async {
                        final url = widget.order['uploadToAmazon'];
                        html.window.open(url, '_blank');
                      },
                      child: const Text(
                        "View Proof of Delivery",
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  )
                      :ElevatedButton.icon(
                    onPressed: uploadToAmazon,
                    icon: const Icon(Icons.upload_file, color: Colors.white),
                    label: const Text("Upload to Amazon", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  widget.order['proofOfDeliveryUrl'] != ""?
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: InkWell(
                      onTap: () async {
                        final url = widget.order['proofOfDeliveryUrl'];
                        html.window.open(url, '_blank');
                      },
                      child: const Text(
                        "View Proof of Delivery",
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ):
                  Center(
                    child: SizedBox(
                      width: 300,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                        icon: const Icon(Icons.attach_file),
                        label: const Text("Upload Proof of Delivery"),
                        onPressed: uploadProofOfDelivery,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Center(
                    child: SizedBox(
                      width: 300,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                        icon: const Icon(Icons.download),
                        label: const Text("Delivery Note"),
                        onPressed: () {
                          deliveryNote(products, widget.order);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text("Products", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SingleChildScrollView(
              child: LayoutBuilder(
                  builder: (context, constraints) {
                  return IntrinsicWidth(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: constraints.maxWidth),
                      child: DataTable(
                        columnSpacing: 20,
                        dataRowMinHeight: 50,
                        dataRowMaxHeight: 100,
                        columns: const [
                          DataColumn(label: Text('')),
                          DataColumn(label: Text('Product')),
                          DataColumn(label: Text('Requested')),
                          DataColumn(label: Text('Confirmed')),
                          DataColumn(label: Text('Batch No')),
                          DataColumn(label: Text('Expiry Date')),
                          DataColumn(label: Text('Unit Cost')),
                          DataColumn(label: Text('Total')),
                        ],
                        rows: products.asMap().entries.map((entry) {
                          final index = entry.key;
                          final product = entry.value;
                          final boxCount = product['boxCount'] ?? 0;
                          final unitCost = product['unitCost'] ?? 0.0;
                          int confirmed = product['confirmed'] ?? 0;

                          final controller = TextEditingController(text: confirmed.toString());

                          return DataRow(cells: [
                            DataCell(
                              CircleAvatar(
                                  radius: 25,
                                  child: Image.network(product['imageUrl'] ?? '', width: 50, height: 50, fit: BoxFit.cover)),
                            ),
                            DataCell(
                              Text(
                                insertLineBreaks(product['title'] ?? '', 40),
                                softWrap: true,
                              ),
                            ),
                            DataCell(Text(boxCount.toString())),

                            // Confirmed with increment/decrement
                            DataCell(
                              SizedBox(
                                width: 140,
                                child: Card(
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline),
                                        onPressed: confirmed > 0
                                            ? () {
                                          setState(() {
                                            confirmed--;
                                            controller.text = confirmed.toString();
                                            products[index]['confirmed'] = confirmed;
                                            products[index]['total'] = confirmed * unitCost;
                                          });
                                        }
                                            : null,
                                      ),
                                      SizedBox(
                                        width: 50,
                                        child: TextField(
                                          controller: controller,
                                          textAlign: TextAlign.center,
                                          keyboardType: TextInputType.number,
                                          onChanged: (value) {
                                            int current = int.tryParse(value) ?? 0;
                                            if (current > boxCount) {
                                              current = boxCount;
                                              controller.text = current.toString();
                                            } else if (current < 0) {
                                              current = 0;
                                              controller.text = "0";
                                            }
                                            setState(() {
                                              products[index]['confirmed'] = current;
                                              products[index]['total'] = current * unitCost;
                                            });
                                          },
                                          decoration: const InputDecoration(
                                            border: InputBorder.none,
                                            isDense: true,
                                            contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline),
                                        onPressed: confirmed < boxCount
                                            ? () {
                                          setState(() {
                                            confirmed++;
                                            controller.text = confirmed.toString();
                                            products[index]['confirmed'] = confirmed;
                                            products[index]['total'] = confirmed * unitCost;
                                          });
                                        }
                                            : null,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Batch No
                            DataCell(
                              SizedBox(
                                width: 120,
                                child: TextFormField(
                                  initialValue: product['batchNo'],
                                  onChanged: (value) {
                                    product['batchNo'] = value;
                                  },
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    contentPadding: EdgeInsets.all(6),
                                    hintText: "Batch No",
                                  ),
                                ),
                              ),
                            ),

// Expiry Date
                            DataCell(
                              SizedBox(
                                width: 120,
                                child: TextFormField(
                                  initialValue: product['expiryDate'],
                                  onChanged: (value) {
                                    product['expiryDate'] = value;
                                  },
                                  inputFormatters: [
                                    ExpiryDateFormatter(),
                                  ],
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    contentPadding: EdgeInsets.all(6),
                                    hintText: "DD/MM/YYYY",
                                  ),
                                ),
                              ),
                            ),


                            DataCell(Text((product['unitCost'] ?? 0.0).toStringAsFixed(2))),
                            DataCell(Text((product['total'] ?? 0.0).toStringAsFixed(2))),

                          ]);
                        }).toList(),
                      ),
                    ),
                  );
                }
              ),
            ),
            const SizedBox(
              height: 30,
            ),
            Center(
              child: SizedBox(
                width: 300,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                  onPressed: () async {
                    await FirebaseFirestore.instance.collection('orders').doc(widget.order.id).update({
                      'boxCount': int.tryParse(boxesController.text.trim()) ?? 0,
                      'products': products, // 🔁 Save updated confirmed counts
                      'status': 'Units Confirmed',
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Order details updated")),
                    );
                  },


                  child: const Text("Save Order Info"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
