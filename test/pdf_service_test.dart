import 'package:flutter_test/flutter_test.dart';
import 'package:loan_calculator/models/loan.dart';
import 'package:loan_calculator/services/pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('PdfService buildPdfDocument creates valid PDF for Manat (₼) with no missing glyphs', () async {
    final loan = Loan(
      id: 'test-1',
      name: 'Ipoteka Krediti',
      totalAmount: 20000,
      interestRate: 12,
      termMonths: 36,
      paymentDay: 15,
      createdAt: DateTime(2025, 1, 1),
    );

    final pdf = await PdfService.buildPdfDocument(loan, '₼');
    final bytes = await pdf.save();

    expect(bytes, isNotEmpty);
    expect(pdf.document.pdfPageList.pages, isNotEmpty);
  });

  test('PdfService resolvePdfCurrency formats symbols safely for standard PDF engines', () {
    expect(PdfService.resolvePdfCurrency('₼'), 'AZN ');
    expect(PdfService.resolvePdfCurrency('€'), 'EUR ');
    expect(PdfService.resolvePdfCurrency('₺'), 'TRY ');
    expect(PdfService.resolvePdfCurrency('₽'), 'RUB ');
    expect(PdfService.resolvePdfCurrency(r'$'), r'$');
    expect(PdfService.resolvePdfCurrency('£'), '£');
  });
}
