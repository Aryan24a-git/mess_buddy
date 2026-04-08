import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../dashboard/domain/models/expense.dart';
import '../../analytics/presentation/providers/analytics_provider.dart';

class PdfExportService {
  // ─── Color Palette (matching the reference template) ───────────────────────
  static const _purple   = PdfColors.deepPurple;
  static const _blue     = PdfColors.blue;
  static const _green    = PdfColors.green;
  static const _orange   = PdfColors.orange;
  static const _red      = PdfColors.red;
  static const _darkGray = PdfColors.blueGrey800;
  static const _darkBlue = PdfColors.indigo900;

  static Future<void> generateAndShareFinancialReport({
    required String userName,
    required List<Expense> recentExpenses,
    required AnalyticsData analytics,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.plusJakartaSansRegular();
    final fontBold = await PdfGoogleFonts.plusJakartaSansBold();

    final fmt = DateFormat('dd/MM');
    final now = DateTime.now();
    final monthStr = DateFormat('MMMM yyyy').format(now);

    // Categorised data
    final messExp    = recentExpenses.where((e) => e.category.toLowerCase().contains('mess')).toList();
    final foodExp    = recentExpenses.where((e) => e.category.toLowerCase().contains('food') || e.category.toLowerCase().contains('outside')).toList();
    final shopExp    = recentExpenses.where((e) => e.category.toLowerCase().contains('shop') || e.category.toLowerCase().contains('purchase') || e.category.toLowerCase().contains('clothe')).toList();
    final billExp    = recentExpenses.where((e) => e.category.toLowerCase().contains('rent') || e.category.toLowerCase().contains('bill') || e.category.toLowerCase().contains('fee') || e.category.toLowerCase().contains('internet')).toList();
    final festExp    = recentExpenses.where((e) => e.isSplit && e.splitWith != null).toList();
    final usedCats   = {'mess', 'food', 'outside', 'shop', 'purchase', 'clothe', 'rent', 'bill', 'fee', 'internet'};
    final miscExp    = recentExpenses.where((e) { final c = e.category.toLowerCase(); return !usedCats.any((u) => c.contains(u)) && !e.isSplit; }).toList();

    final messTotal  = messExp.fold(0.0, (s, e) => s + e.amount);
    final foodTotal  = foodExp.fold(0.0, (s, e) => s + e.amount);
    final shopTotal  = shopExp.fold(0.0, (s, e) => s + e.amount);
    final billTotal  = billExp.fold(0.0, (s, e) => s + e.amount);
    final festTotal  = festExp.fold(0.0, (s, e) => s + e.amount);
    final miscTotal  = miscExp.fold(0.0, (s, e) => s + e.amount);
    final grandTotal = messTotal + foodTotal + shopTotal + billTotal + festTotal + miscTotal;

    String rs(double v) => '₹${v.toStringAsFixed(0)}';

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (ctx) => [

        // ───────────────────────── HEADER BANNER ─────────────────────────
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          color: _purple,
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('PERSONAL EXPENSE TRACKER', style: pw.TextStyle(font: fontBold, fontSize: 20, color: PdfColors.white)),
            pw.SizedBox(height: 4),
            pw.Text('User: $userName  |  Month: $monthStr  |  Generated: ${DateFormat('dd MMM yyyy').format(now)}',
                style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey300)),
          ]),
        ),
        pw.SizedBox(height: 16),

        // ───────────────────────── SECTION 1: MESS ───────────────────────
        _sectionHeader('SECTION 1: MESS EXPENSES', _blue, fontBold),
        _expenseTable(
          font: font, fontBold: fontBold, headerColor: _blue,
          headers: ['Date', 'Food Item', 'Food Price', 'Extra Item', 'Extra Price', 'Total'],
          rows: messExp.map((e) => [fmt.format(e.date), e.title, rs(e.amount), '-', '0', rs(e.amount)]).toList(),
          totalLabel: 'TOTAL SPENDING (MESS)',
          total: rs(messTotal),
        ),
        pw.SizedBox(height: 14),

        // ───────────────────────── SECTION 2: OUTSIDE ────────────────────
        _sectionHeader('SECTION 2: OUTSIDE MESS SPENDING', _green, fontBold),
        pw.Text('Outside Food', style: pw.TextStyle(font: fontBold, fontSize: 10, color: _green)),
        _expenseTable(
          font: font, fontBold: fontBold, headerColor: _green,
          headers: ['Date', 'Food Item', 'Price (Rs.)'],
          rows: foodExp.map((e) => [fmt.format(e.date), e.title, rs(e.amount)]).toList(),
          totalLabel: 'Food Sub-Total',
          total: rs(foodTotal),
          compact: true,
        ),
        pw.SizedBox(height: 6),
        pw.Text('Shopping / Purchases', style: pw.TextStyle(font: fontBold, fontSize: 10, color: _orange)),
        _expenseTable(
          font: font, fontBold: fontBold, headerColor: _orange,
          headers: ['Date', 'Item Bought', 'Price (Rs.)'],
          rows: shopExp.map((e) => [fmt.format(e.date), e.title, rs(e.amount)]).toList(),
          totalLabel: 'Shopping Sub-Total',
          total: rs(shopTotal),
          compact: true,
        ),
        _totalBand('OUTSIDE TOTAL (Food + Shopping): ${rs(foodTotal + shopTotal)}', fontBold),
        pw.SizedBox(height: 14),

        // ───────────────────────── SECTION 3: BILLS ──────────────────────
        _sectionHeader('SECTION 3: RENT / BILLS / FEES', _purple, fontBold),
        _expenseTable(
          font: font, fontBold: fontBold, headerColor: _purple,
          headers: ['Category', 'Description', 'Amount (Rs.)'],
          rows: [
            ...billExp.map((e) => [e.category, e.title, rs(e.amount)]),
            if (billExp.isEmpty) ['(None recorded)', '-', '₹0'],
          ],
          totalLabel: 'BILLS TOTAL',
          total: rs(billTotal),
          compact: true,
        ),
        pw.SizedBox(height: 14),

        // ───────────────────────── SECTION 4: FRIENDS ────────────────────
        _sectionHeader('SECTION 4: FRIENDS / FESTIVAL / COLLEGE FEST PAYMENTS', _red, fontBold),
        _expenseTable(
          font: font, fontBold: fontBold, headerColor: _red,
          headers: ['Date', 'Event / Festival', 'Paid For', 'Amount (Rs.)'],
          rows: festExp.isNotEmpty
              ? festExp.map((e) => [fmt.format(e.date), e.title, e.splitWith ?? '-', rs(e.amount)]).toList()
              : [['-', '-', '-', '₹0']],
          totalLabel: 'FRIENDS PAYMENTS TOTAL',
          total: rs(festTotal),
          compact: true,
        ),
        pw.SizedBox(height: 14),

        // ───────────────────────── SECTION 5: DEBTS ──────────────────────
        _sectionHeader('SECTION 5: DEBTS & BORROWING TRACKER', _blue, fontBold),
        _expenseTable(
          font: font, fontBold: fontBold, headerColor: _blue,
          headers: ['Person', 'Total Amount', 'Remaining', 'Direction', 'Status'],
          rows: [
            ['You → Roommates', rs(analytics.youOweTotal), rs(analytics.youOweTotal), 'You Owe', 'Pending'],
            ['Roommates → You', rs(analytics.othersOweTotal), rs(analytics.othersOweTotal), 'Owed to You', 'Pending'],
          ],
          compact: true,
        ),
        pw.SizedBox(height: 14),

        // ───────────────────────── SECTION 6: MISC ───────────────────────
        _sectionHeader('SECTION 6: OTHERS / MISCELLANEOUS', _darkGray, fontBold),
        _expenseTable(
          font: font, fontBold: fontBold, headerColor: _darkGray,
          headers: ['Date', 'Description', 'Amount (Rs.)'],
          rows: miscExp.isNotEmpty
              ? miscExp.map((e) => [fmt.format(e.date), e.title, rs(e.amount)]).toList()
              : [['-', '-', '₹0']],
          totalLabel: 'MISC TOTAL',
          total: rs(miscTotal),
          compact: true,
        ),
        pw.SizedBox(height: 20),

        // ───────────────────────── SECTION 7: SUMMARY ────────────────────
        _sectionHeader('MONTHLY SUMMARY DASHBOARD', _darkBlue, fontBold),
        pw.TableHelper.fromTextArray(
          headers: ['Category', 'Amount (Rs.)'],
          headerStyle: pw.TextStyle(font: fontBold, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: _darkBlue),
          cellStyle: pw.TextStyle(font: font, fontSize: 11),
          data: [
            ['Mess Expenses', rs(messTotal)],
            ['Outside Food + Shopping', rs(foodTotal + shopTotal)],
            ['Rent / Bills / Fees', rs(billTotal)],
            ['Friends / Festival Payments', rs(festTotal)],
            ['Others / Miscellaneous', rs(miscTotal)],
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Container(
          color: _blue,
          padding: const pw.EdgeInsets.all(8),
          child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('GRAND TOTAL', style: pw.TextStyle(font: fontBold, fontSize: 14, color: PdfColors.white)),
            pw.Text(rs(grandTotal), style: pw.TextStyle(font: fontBold, fontSize: 14, color: PdfColors.white)),
          ]),
        ),
      ],
      footer: (ctx) => pw.Container(
        alignment: pw.Alignment.centerRight,
        padding: const pw.EdgeInsets.only(top: 8),
        decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300))),
        child: pw.Text(
          'Page ${ctx.pageNumber} of ${ctx.pagesCount} • Auto-generated by Mess Buddy',
          style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey500),
        ),
      ),
    ));

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'MessBuddy_Expense_Tracker_${DateFormat('MMM_yyyy').format(now)}.pdf',
    );
  }

  // ─── Builder Helpers ───────────────────────────────────────────────────────

  static pw.Widget _sectionHeader(String title, PdfColor color, pw.Font fontBold) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      color: color,
      margin: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(title, style: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColors.white)),
    );
  }

  static pw.Widget _expenseTable({
    required pw.Font font,
    required pw.Font fontBold,
    required PdfColor headerColor,
    required List<String> headers,
    required List<List<String>> rows,
    String? totalLabel,
    String? total,
    bool compact = false,
  }) {
    final data = rows.isEmpty ? [List.filled(headers.length, '-')] : rows;

    return pw.Column(children: [
      pw.TableHelper.fromTextArray(
        headers: headers,
        headerStyle: pw.TextStyle(font: fontBold, color: PdfColors.white, fontSize: compact ? 9 : 10),
        headerDecoration: pw.BoxDecoration(color: headerColor),
        cellStyle: pw.TextStyle(font: font, fontSize: compact ? 9 : 10),
        cellDecoration: (i, _, __) => pw.BoxDecoration(
          color: i.isEven ? PdfColors.white : PdfColors.grey100,
        ),
        data: data,
      ),
      if (totalLabel != null && total != null)
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          color: PdfColors.yellow200,
          child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text(totalLabel, style: pw.TextStyle(font: fontBold, fontSize: compact ? 9 : 10)),
            pw.Text(total, style: pw.TextStyle(font: fontBold, fontSize: compact ? 9 : 10)),
          ]),
        ),
    ]);
  }

  static pw.Widget _totalBand(String text, pw.Font fontBold) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(6),
      color: PdfColors.yellow200,
      child: pw.Text(text, style: pw.TextStyle(font: fontBold, fontSize: 10), textAlign: pw.TextAlign.right),
    );
  }
}
