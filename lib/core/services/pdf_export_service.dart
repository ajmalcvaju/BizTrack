import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../../features/customers/models/customer_model.dart';
import '../../features/customers/models/payment_model.dart';
import '../../features/payments/models/expense_model.dart';

class PdfExportService {
  static final PdfExportService _instance = PdfExportService._internal();
  factory PdfExportService() => _instance;
  PdfExportService._internal();

  /// Export Customer Outstanding Report to PDF
  Future<void> exportOutstandingPdf({
    required List<CustomerModel> customers,
    required String businessName,
  }) async {
    final pdf = pw.Document();

    final outstandingList =
        customers.where((c) => c.balanceAmount > 0).toList();
    final totalOutstanding =
        outstandingList.fold(0, (sum, c) => sum + c.balanceAmount);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildPdfHeader('Customer Outstanding Report', businessName),
          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total Outstanding Accounts: ${outstandingList.length}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(
                  'Total Balance: ${CurrencyFormatter.formatPaise(totalOutstanding)}',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.red800,
                      fontSize: 14),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: [
              'Shop Name',
              'Customer Name',
              'Phone',
              'Status',
              'Total (₹)',
              'Paid (₹)',
              'Balance (₹)'
            ],
            data: outstandingList.map((c) {
              return [
                c.shopName,
                c.customerName,
                c.contactNumber,
                c.workStatus,
                CurrencyFormatter.formatPaise(c.totalWorkAmount),
                CurrencyFormatter.formatPaise(c.totalAmountReceived),
                CurrencyFormatter.formatPaise(c.balanceAmount),
              ];
            }).toList(),
            headerStyle:
                pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
            cellHeight: 28,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.center,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.centerRight,
              6: pw.Alignment.centerRight,
            },
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'BizPilot_Outstanding_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  /// Export Collection History to PDF
  Future<void> exportCollectionPdf({
    required List<PaymentModel> payments,
    required List<CustomerModel> customers,
    required String businessName,
    required String period,
  }) async {
    final pdf = pw.Document();

    final customerMap = {for (var c in customers) c.id: c};
    final totalCollected =
        payments.fold(0, (sum, p) => sum + p.amountReceived);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildPdfHeader('Payment Collection Report ($period)', businessName),
          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.green50,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total Payments: ${payments.length}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(
                  'Total Collected: ${CurrencyFormatter.formatPaise(totalCollected)}',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green800,
                      fontSize: 14),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: [
              'Date',
              'Customer Name',
              'Shop Name',
              'Account',
              'Method',
              'Remarks',
              'Amount (₹)'
            ],
            data: payments.map((p) {
              final c = customerMap[p.customerId];
              return [
                DateFormatter.formatDate(p.paymentDate),
                c?.customerName ?? 'Unknown',
                c?.shopName ?? '-',
                p.accountType,
                p.paymentMethod,
                p.remarks,
                CurrencyFormatter.formatPaise(p.amountReceived),
              ];
            }).toList(),
            headerStyle:
                pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.teal800),
            cellHeight: 28,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.center,
              4: pw.Alignment.center,
              5: pw.Alignment.centerLeft,
              6: pw.Alignment.centerRight,
            },
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'BizPilot_Collection_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  /// Export Customers to CSV / Excel
  Future<void> exportCustomersCsv(List<CustomerModel> customers) async {
    final rows = <List<dynamic>>[];
    rows.add([
      'Shop Name',
      'Customer Name',
      'Contact Number',
      'Address',
      'Work Status',
      'Work Details',
      'Total Work Amount (₹)',
      'Total Received (₹)',
      'Balance (₹)',
      'Remarks',
    ]);

    for (final c in customers) {
      rows.add([
        c.shopName,
        c.customerName,
        c.contactNumber,
        c.address,
        c.workStatus,
        c.workDetails,
        (c.totalWorkAmount / 100).toStringAsFixed(2),
        (c.totalAmountReceived / 100).toStringAsFixed(2),
        (c.balanceAmount / 100).toStringAsFixed(2),
        c.customerRemarks,
      ]);
    }

    final csvData = const ListToCsvConverter().convert(rows);
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/BizPilot_Customers_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csvData);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      text: 'BizPilot Customers Export',
    );
  }

  /// Export Expenses to CSV
  Future<void> exportExpensesCsv(List<ExpenseModel> expenses) async {
    final rows = <List<dynamic>>[];
    rows.add([
      'Date',
      'Title',
      'Account Type',
      'Category',
      'Amount (₹)',
      'Remarks',
    ]);

    for (final e in expenses) {
      rows.add([
        DateFormatter.formatDate(e.date),
        e.title,
        e.accountType,
        e.category,
        (e.amount / 100).toStringAsFixed(2),
        e.remarks,
      ]);
    }

    final csvData = const ListToCsvConverter().convert(rows);
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/BizPilot_Expenses_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csvData);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      text: 'BizPilot Expenses Export',
    );
  }

  pw.Widget _buildPdfHeader(String title, String businessName) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('BIZPILOT',
                    style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800)),
                pw.Text('Business Manager & Financial Suite',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(businessName,
                    style: pw.TextStyle(
                        fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.Text('Date: ${DateFormatter.formatDate(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Divider(color: PdfColors.grey400),
        pw.SizedBox(height: 8),
        pw.Text(title,
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }
}
