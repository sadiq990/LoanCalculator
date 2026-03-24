import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/loan.dart';

/// Enhanced PDF Service with professional amortization schedule layout
class PdfService {
  static Future<void> generateLoanReport(
    Loan loan,
    String currencySymbol,
  ) async {
    final pdf = pw.Document();

    final currencyFormat = NumberFormat.currency(
      symbol: currencySymbol,
      decimalDigits: 2,
    );
    final dateFormat = DateFormat('MMMM d, yyyy');
    final monthYearFormat = DateFormat('MMM yyyy');

    final schedule = loan.getOriginalAmortizationSchedule();
    final totalInterest = schedule.fold<double>(0, (sum, e) => sum + e.interest);
    final payoffDate = schedule.isNotEmpty ? schedule.last.date : loan.createdAt;
    final simulation = loan.simulatePayoff();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(loan, dateFormat),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          // Loan Details Section
          _buildSectionTitle('LOAN DETAILS'),
          pw.SizedBox(height: 8),
          _buildLoanDetailsCard(loan, currencyFormat),
          pw.SizedBox(height: 20),

          // Summary Statistics
          _buildSectionTitle('SUMMARY'),
          pw.SizedBox(height: 8),
          _buildSummaryCard(loan, simulation, totalInterest, payoffDate, currencyFormat),
          pw.SizedBox(height: 20),

          // Payment Schedule
          _buildSectionTitle('PAYMENT SCHEDULE'),
          pw.SizedBox(height: 8),
          _buildPaymentTable(schedule, currencyFormat, monthYearFormat),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${loan.name.replaceAll(' ', '_')}_Amortization.pdf',
    );
  }

  static pw.Widget _buildHeader(Loan loan, DateFormat dateFormat) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 20),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 1)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'LOAN TRACKER',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Amortization Schedule',
                style: const pw.TextStyle(
                  fontSize: 14,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                loan.name,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Generated: ${dateFormat.format(DateTime.now())}',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Loan Tracker App',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 14,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.blue800,
        letterSpacing: 1.5,
      ),
    );
  }

  static pw.Widget _buildLoanDetailsCard(Loan loan, NumberFormat currencyFormat) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Principal Amount', currencyFormat.format(loan.totalAmount)),
                _buildDetailRow('Interest Rate', '${loan.interestRate}% APR'),
                _buildDetailRow('Loan Term', '${loan.termMonths} Months'),
              ],
            ),
          ),
          pw.SizedBox(width: 40),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Monthly Payment', currencyFormat.format(loan.monthlyRequired)),
                _buildDetailRow('Start Date', DateFormat('MMM d, yyyy').format(loan.createdAt)),
                _buildDetailRow('Payment Day', '${loan.paymentDay}${_getDaySuffix(loan.paymentDay)}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }

  static pw.Widget _buildSummaryCard(
    Loan loan,
    PayoffSimulation simulation,
    double totalInterest,
    DateTime payoffDate,
    NumberFormat currencyFormat,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: PdfColors.blue100),
      ),
      child: pw.Row(
        children: [
          _buildSummaryItem('Total Payments', currencyFormat.format(loan.totalContractValue), PdfColors.blue800),
          pw.Container(width: 1, height: 40, color: PdfColors.blue200),
          _buildSummaryItem('Total Interest', currencyFormat.format(totalInterest), PdfColors.red600),
          pw.Container(width: 1, height: 40, color: PdfColors.blue200),
          _buildSummaryItem('Payoff Date', DateFormat('MMM yyyy').format(payoffDate), PdfColors.green700),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryItem(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPaymentTable(
    List<AmortizationEntry> schedule,
    NumberFormat currencyFormat,
    DateFormat monthYearFormat,
  ) {
    // Show first 60 entries or all if less
    final displaySchedule = schedule.length > 60 ? schedule.sublist(0, 60) : schedule;
    final hasMore = schedule.length > 60;

    return pw.Column(
      children: [
        // Table Header
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: const pw.BoxDecoration(
            color: PdfColors.blue700,
            borderRadius: pw.BorderRadius.only(
              topLeft: pw.Radius.circular(6),
              topRight: pw.Radius.circular(6),
            ),
          ),
          child: pw.Row(
            children: [
              _tableHeaderCell('#', 30),
              _tableHeaderCell('Date', 70),
              _tableHeaderCell('Payment', 80),
              _tableHeaderCell('Principal', 80),
              _tableHeaderCell('Interest', 80),
              _tableHeaderCell('Balance', 90),
            ],
          ),
        ),
        // Table Body
        pw.ListView.builder(
          itemCount: displaySchedule.length + (hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (hasMore && index == displaySchedule.length) {
              return pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 8),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300)),
                ),
                child: pw.Center(
                  child: pw.Text(
                    '... ${schedule.length - 60} more payments ...',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
                  ),
                ),
              );
            }

            final entry = displaySchedule[index];
            final bgColor = index % 2 == 0 ? PdfColors.white : PdfColors.grey50;
            final statusColor = entry.isPaid ? PdfColors.green700 : PdfColors.grey700;

            return pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              decoration: pw.BoxDecoration(
                color: bgColor,
                border: const pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5)),
              ),
              child: pw.Row(
                children: [
                  _tableCell('${entry.monthIndex}', 30, alignment: pw.Alignment.centerLeft),
                  _tableCell(monthYearFormat.format(entry.date), 70),
                  _tableCell(currencyFormat.format(entry.payment), 80),
                  _tableCell(currencyFormat.format(entry.principal), 80),
                  _tableCell(currencyFormat.format(entry.interest), 80),
                  _tableCell(currencyFormat.format(entry.remainingBalance), 90,
                      color: entry.remainingBalance <= 0 ? PdfColors.green700 : PdfColors.black),
                ],
              ),
            );
          },
        ),
        // Last row highlight
        if (schedule.isNotEmpty)
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: const pw.BoxDecoration(
              color: PdfColors.green50,
              borderRadius: pw.BorderRadius.only(
                bottomLeft: pw.Radius.circular(6),
                bottomRight: pw.Radius.circular(6),
              ),
            ),
            child: pw.Row(
              children: [
                _tableCell('', 30),
                _tableCell('', 70),
                _tableCell('', 80),
                _tableCell('', 80),
                _tableCell('', 80),
                _tableCell('PAID OFF', 90, isBold: true, color: PdfColors.green700),
              ],
            ),
          ),
      ],
    );
  }

  static pw.Widget _tableHeaderCell(String text, double width) {
    return pw.Container(
      width: width,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  static pw.Widget _tableCell(
    String text,
    double width, {
    pw.Alignment alignment = pw.Alignment.centerRight,
    PdfColor? color,
    bool isBold = false,
  }) {
    return pw.Container(
      width: width,
      alignment: alignment,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? PdfColors.black,
        ),
      ),
    );
  }
}
