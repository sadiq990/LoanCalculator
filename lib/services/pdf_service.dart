import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/loan.dart';


class PdfService {
  static Future<void> generateLoanReport(
    Loan loan,
    String currencySymbol,
  ) async {
    final pdf = pw.Document();

    // Create formatters
    final currencyFormat = NumberFormat.currency(
      symbol: currencySymbol,
      decimalDigits: 2,
    );
    final dateFormat = DateFormat('MMM d, yyyy');

    // Add page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Loan Statement',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      dateFormat.format(DateTime.now()),
                      style: const pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Loan Details
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(5),
                  ),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow('Loan Name', loan.name),
                          _buildDetailRow(
                            'Total Amount',
                            currencyFormat.format(loan.totalAmount),
                          ),
                          _buildDetailRow(
                            'Interest Rate',
                            '${loan.interestRate}%',
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 20),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow('Term', '${loan.termMonths} Months'),
                          _buildDetailRow(
                            'Monthly Payment',
                            currencyFormat.format(loan.monthlyRequired),
                          ),
                          _buildDetailRow(
                            'Remaining Debt',
                            currencyFormat.format(loan.remainingDebt),
                            isBold: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),

              // Payment History Title
              pw.Text(
                'Payment History',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),

              // Table
              pw.TableHelper.fromTextArray(
                context: context,
                border: null,
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blue600,
                ),
                rowDecoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey200),
                  ),
                ),
                cellPadding: const pw.EdgeInsets.all(8),
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerRight,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.centerRight,
                  4: pw.Alignment.centerRight,
                  5: pw.Alignment.center,
                },
                headers: ['Date', 'Total Pmt', 'Principal', 'Interest', 'Balance', 'Status'],
                data: _generatePaymentData(loan, currencyFormat, dateFormat),
              ),

              pw.Spacer(),
              pw.Divider(),
              pw.Center(
                child: pw.Text(
                  'Generated by Loan Tracker App',
                  style: const pw.TextStyle(color: PdfColors.grey),
                ),
              ),
            ],
          );
        },
      ),
    );

    // Show Print/Share Dialog
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${loan.name}_Statement.pdf',
    );
  }

  static pw.Widget _buildDetailRow(
    String label,
    String value, {
    bool isBold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(color: PdfColors.grey700)),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  static List<List<String>> _generatePaymentData(
    Loan loan,
    NumberFormat currency,
    DateFormat date,
  ) {
    final schedule = loan.getOriginalAmortizationSchedule();
    if (schedule.isEmpty) {
      return [['-', '-', '-', '-', '-', '-']];
    }

    return schedule.map((entry) {
      return [
        date.format(entry.date),
        currency.format(entry.payment),
        currency.format(entry.principal),
        currency.format(entry.interest),
        currency.format(entry.remainingBalance),
        entry.isPaid ? 'Paid' : 'Unpaid'
      ];
    }).toList();
  }
}
