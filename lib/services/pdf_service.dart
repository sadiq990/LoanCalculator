import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/loan.dart';
import '../models/amortization_entry.dart';
import '../core/constants/app_disclaimers.dart';

/// Enhanced PDF Service with professional amortization schedule layout
class PdfService {
  /// Maps currency symbols to safe, standard ISO 4217 / ASCII codes for PDF engines
  static String resolvePdfCurrency(String symbol) {
    final s = symbol.trim();
    switch (s) {
      case '₼':
        return 'AZN ';
      case '₺':
        return 'TRY ';
      case '₽':
        return 'RUB ';
      case '€':
        return 'EUR ';
      default:
        return s.isEmpty ? '' : (s == r'$' || s == '£' ? s : '$s ');
    }
  }

  /// Builds a complete PDF document for the loan report
  static Future<pw.Document> buildPdfDocument(
    Loan loan,
    String currencySymbol,
  ) async {
    final pdfSymbol = resolvePdfCurrency(currencySymbol);

    pw.ThemeData theme;
    try {
      final regular = await PdfGoogleFonts.notoSansRegular();
      final bold = await PdfGoogleFonts.notoSansBold();
      theme = pw.ThemeData.withFont(base: regular, bold: bold);
    } catch (_) {
      theme = pw.ThemeData.base();
    }

    final pdf = pw.Document(theme: theme);

    final currencyFormat = NumberFormat.currency(
      symbol: pdfSymbol,
      decimalDigits: 2,
    );
    final dateFormat = DateFormat('MMMM d, yyyy');
    final monthYearFormat = DateFormat('MMM yyyy');

    final schedule = loan.getOriginalAmortizationSchedule();
    final totalInterest = schedule.fold<double>(0, (sum, e) => sum + e.interest);
    final payoffDate = schedule.isNotEmpty ? schedule.last.date : loan.createdAt;
    final simulation = loan.simulatePayoff();
    final totalPaid = loan.totalPaid;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (context) => _buildHeader(loan, dateFormat),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          // Loan Details Section
          _buildSectionTitle('LOAN DETAILS'),
          pw.SizedBox(height: 8),
          _buildLoanDetailsCard(loan, currencyFormat),
          pw.SizedBox(height: 16),

          // Summary Statistics
          _buildSectionTitle('SUMMARY'),
          pw.SizedBox(height: 8),
          _buildSummaryCard(loan, simulation, totalInterest, payoffDate, totalPaid, currencyFormat),
          pw.SizedBox(height: 16),

          // Payment Schedule
          _buildSectionTitle('PAYMENT SCHEDULE'),
          pw.SizedBox(height: 8),
          _buildPaymentTable(schedule, currencyFormat, monthYearFormat),
        ],
      ),
    );

    return pdf;
  }

  static Future<void> generateLoanReport(
    Loan loan,
    String currencySymbol,
  ) async {
    final pdf = await buildPdfDocument(loan, currencySymbol);
    final sanitizedName = loan.name.replaceAll(RegExp(r'[^\w\s-]'), '').trim().replaceAll(' ', '_');

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${sanitizedName}_Amortization.pdf',
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
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            AppDisclaimers.financialDisclaimer,
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Loan Tracker',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
              ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
              ),
            ],
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
    double totalPaid,
    NumberFormat currencyFormat,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: PdfColors.blue100),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            children: [
              _buildSummaryItem('Total Paid', currencyFormat.format(totalPaid), PdfColors.green700),
              pw.Container(width: 1, height: 40, color: PdfColors.blue200),
              _buildSummaryItem('Total Due', currencyFormat.format(loan.totalContractValue), PdfColors.blue800),
              pw.Container(width: 1, height: 40, color: PdfColors.blue200),
              _buildSummaryItem('Remaining', currencyFormat.format(loan.totalContractValue - totalPaid), PdfColors.orange700),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Divider(color: PdfColors.blue200),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              _buildSummaryItem('Total Interest', currencyFormat.format(totalInterest), PdfColors.red600),
              pw.Container(width: 1, height: 40, color: PdfColors.blue200),
              _buildSummaryItem('Payoff Date', DateFormat('MMM yyyy').format(payoffDate), PdfColors.green700),
              pw.Spacer(),
            ],
          ),
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
    // Show up to 120 entries or all if less
    final displaySchedule = schedule.length > 120 ? schedule.sublist(0, 120) : schedule;
    final hasMore = schedule.length > 120;

    return pw.Table(
      border: const pw.TableBorder(
        bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        horizontalInside: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
      ),
      columnWidths: {
        0: const pw.FixedColumnWidth(40),
        1: const pw.FixedColumnWidth(25),
        2: const pw.FixedColumnWidth(60),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(1),
        5: const pw.FlexColumnWidth(1),
        6: const pw.FlexColumnWidth(1.1),
      },
      children: [
        // Table Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue700),
          repeat: true,
          children: [
            _tableHeaderCell('Status', 40, alignment: pw.Alignment.centerLeft),
            _tableHeaderCell('#', 25, alignment: pw.Alignment.centerLeft),
            _tableHeaderCell('Date', 60, alignment: pw.Alignment.centerLeft),
            _tableHeaderCell('Payment', null),
            _tableHeaderCell('Principal', null),
            _tableHeaderCell('Interest', null),
            _tableHeaderCell('Balance', null),
          ],
        ),
        // Table Rows
        ...displaySchedule.asMap().entries.map((item) {
          final index = item.key;
          final entry = item.value;
          final bgColor = entry.isPaid
              ? PdfColors.green50
              : (index % 2 == 0 ? PdfColors.white : PdfColors.grey50);
          final status = entry.isPaid ? 'Paid' : '-';
          final statusColor = entry.isPaid ? PdfColors.green700 : PdfColors.grey400;

          return pw.TableRow(
            decoration: pw.BoxDecoration(color: bgColor),
            children: [
              _tableCell(status, 40, color: statusColor, isBold: entry.isPaid, alignment: pw.Alignment.centerLeft),
              _tableCell('${entry.monthIndex}', 25, alignment: pw.Alignment.centerLeft),
              _tableCell(monthYearFormat.format(entry.date), 60, alignment: pw.Alignment.centerLeft),
              _tableCell(currencyFormat.format(entry.payment), null),
              _tableCell(currencyFormat.format(entry.principal), null),
              _tableCell(currencyFormat.format(entry.interest), null),
              _tableCell(
                currencyFormat.format(entry.remainingBalance),
                null,
                color: entry.remainingBalance <= 0 ? PdfColors.green700 : PdfColors.black,
              ),
            ],
          );
        }),
        if (hasMore)
          pw.TableRow(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 8),
                child: pw.Text(
                  '... and ${schedule.length - 120} more payments ...',
                  style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey500),
                ),
              ),
              pw.SizedBox(),
              pw.SizedBox(),
              pw.SizedBox(),
              pw.SizedBox(),
              pw.SizedBox(),
              pw.SizedBox(),
            ],
          ),
        if (schedule.isNotEmpty && schedule.last.remainingBalance <= 0)
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.green50),
            children: [
              _tableCell('DONE', 40, isBold: true, color: PdfColors.green700, alignment: pw.Alignment.centerLeft),
              _tableCell('', 25),
              _tableCell('', 60),
              _tableCell('', null),
              _tableCell('', null),
              _tableCell('', null),
              _tableCell('PAID OFF', null, isBold: true, color: PdfColors.green700),
            ],
          ),
      ],
    );
  }

  static pw.Widget _tableHeaderCell(
    String text,
    double? width, {
    pw.Alignment alignment = pw.Alignment.centerRight,
  }) {
    return pw.Container(
      width: width,
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      alignment: alignment,
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
    double? width, {
    pw.Alignment alignment = pw.Alignment.centerRight,
    PdfColor? color,
    bool isBold = false,
  }) {
    return pw.Container(
      width: width,
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      alignment: alignment,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8.5,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? PdfColors.black,
        ),
      ),
    );
  }
}
