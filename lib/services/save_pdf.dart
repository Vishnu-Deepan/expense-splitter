import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart'; // Import this to use PdfColor
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';

Future<void> exportToPDF(Map<String, dynamic> report) async {
  // Request storage permission
  await checkAndRequestPermissions();

  // Fetch all member names before creating the PDF
  Map<String, String> memberNames = await _fetchMemberNames(report);

  // Create PDF document
  final pdf = pw.Document();

  // Add page to PDF
  pdf.addPage(
    pw.Page(
      build: (pw.Context context) {
        print("Generating page content...");

        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header Section
            pw.Container(
              color: PdfColor.fromInt(0xFF00796B), // Header background color
              padding: pw.EdgeInsets.all(10),
              child: pw.Column(
                children: [
                  pw.Text('Expense Report',
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFFFFFFFF), // White text color
                      )),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Report generated on: ${DateTime.now().toLocal()}',
                    style: pw.TextStyle(
                        fontSize: 12,
                        color:
                            PdfColor.fromInt(0xFFFFFFFF)), // White text color
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Total Expenses Section
            _buildSummarySection(report),

            // Expenses History Section
            _buildExpensesHistorySection(report, memberNames),

            // Individual Expenses Section
            _buildIndividualExpensesSection(report, memberNames),

            // Debts Section
            _buildDebtsSection(report, memberNames),
          ],
        );
      },
    ),
  );

  // Get directory path and save PDF
  final directory = await getExternalStorageDirectory();
  if (directory == null) {
    print("Failed to get directory path!");
    return;
  }

  final path =
      '${directory.path}/ExpenseReport_${DateTime.now().millisecondsSinceEpoch}.pdf';
  final file = File(path);

  try {
    await file.writeAsBytes(await pdf.save());
    print("PDF saved at: $path");
  } catch (e) {
    print("Error saving PDF: $e");
    return;
  }

  // Open PDF
  final result = await OpenFile.open(path);
  print("OpenFile result: $result");
}

// Summary Section (Total Expenses and Split Amount)
pw.Widget _buildSummarySection(Map<String, dynamic> report) {
  final totalExpense = calculateTotalExpense(report['sharedExpenses']);
  final splitAmount = totalExpense / report['members'].length;

  return pw.Container(
    padding: pw.EdgeInsets.all(15),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColor.fromInt(0xFF00796B)),
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Total Expense: Rs.${totalExpense.toStringAsFixed(2)}',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromInt(0xFF00796B),
            )),
        pw.SizedBox(height: 5),
        pw.Text('Split Amount: Rs.${splitAmount.toStringAsFixed(2)}',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromInt(0xFF00796B),
            )),
      ],
    ),
  );
}

// Shared Expenses Section
pw.Widget _buildExpensesHistorySection(
    Map<String, dynamic> report, Map<String, String> memberNames) {
  return pw.Padding(
    padding: pw.EdgeInsets.only(top: 20),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Expenses History:',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        // Table Header for Shared Expenses
        _buildTableHeader(['Expense Title', 'Amount', 'Paid By']),
        // Table Data for Shared Expenses
        ...report['sharedExpenses'].map<pw.Widget>((expense) {
          final memberName = memberNames[expense['paidBy']] ?? 'Unknown';
          return _buildTableRow([
            expense['title'],
            'Rs.${expense['amount']}',
            memberName,
          ]);
        }).toList(),
      ],
    ),
  );
}

// Individual Expenses Section
pw.Widget _buildIndividualExpensesSection(
    Map<String, dynamic> report, Map<String, String> memberNames) {
  return pw.Padding(
    padding: pw.EdgeInsets.only(top: 20),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Individual Expenses:',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        // Table Header for Individual Expenses
        _buildTableHeader(['Member', 'Initial Pay', 'Debt Pay', 'Total']),
        // Table Data for Individual Expenses
        ...report['individualExpenses'].map<pw.Widget>((expense) {
          final memberName = memberNames[expense['memberId']] ?? 'Unknown';
          final total = expense['initialPay'] + expense['debtPay'];
          return _buildTableRow([
            memberName,
            'Rs.${expense['initialPay']}',
            'Rs.${expense['debtPay']}',
            'Rs.$total',
          ]);
        }).toList(),
      ],
    ),
  );
}

// Debts Section
pw.Widget _buildDebtsSection(
    Map<String, dynamic> report, Map<String, String> memberNames) {
  return pw.Padding(
    padding: pw.EdgeInsets.only(top: 20),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Debts:',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        // Table Header for Debts
        _buildTableHeader(['Member', 'Pay To', 'Amount']),
        // Table Data for Debts
        ...report['debts'].map<pw.Widget>((debt) {
          final creditorName = memberNames[debt['docId']] ?? 'Unknown';
          final debtorId = debt['debts'].keys.first; // Debtor ID
          final debtorName = memberNames[debtorId] ?? 'Unknown'; // Debtor Name
          return _buildTableRow([
            creditorName,
            debtorName,
            'Rs.${debt['totalDebt']}',
          ]);
        }).toList(),
      ],
    ),
  );
}

// Table Header
pw.Widget _buildTableHeader(List<String> headers) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: headers
        .map((header) => pw.Expanded(
              child: pw.Text(
                header,
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF00796B),
                ),
              ),
            ))
        .toList(),
  );
}

// Table Row
pw.Widget _buildTableRow(List<String> cells) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: cells
        .map((cell) => pw.Expanded(
              child: pw.Text(cell,
                  style: pw.TextStyle(
                      fontSize: 12, color: PdfColor.fromInt(0xFF333333))),
            ))
        .toList(),
  );
}

// Check and request storage permissions
Future<void> checkAndRequestPermissions() async {
  if (await Permission.storage.request().isGranted) {
    print("Storage permission granted");
  } else {
    print("Storage permission denied");
    await Permission.storage.request();
  }
}

// Fetch Member Names
Future<Map<String, String>> _fetchMemberNames(
    Map<String, dynamic> report) async {
  List memberIds = [
    ...report['sharedExpenses'].map((expense) => expense['paidBy']),
    ...report['individualExpenses'].map((expense) => expense['memberId']),
    ...report['debts'].map((debt) => debt['docId']),
    ...report['debts'].expand((debt) => (debt['debts'] as Map).keys),
  ].toSet().toList();

  final membersQuery = await FirebaseFirestore.instance
      .collection('members')
      .where(FieldPath.documentId, whereIn: memberIds)
      .get();

  return {
    for (var doc in membersQuery.docs) doc.id: doc.data()?['name'] ?? 'Unknown',
  };
}

// Calculate Total Expense
double calculateTotalExpense(List<dynamic> sharedExpenses) {
  double totalExpense = 0.0;
  for (var expense in sharedExpenses) {
    totalExpense += expense['amount'];
  }
  return totalExpense;
}
