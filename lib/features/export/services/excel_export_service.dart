import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../dashboard/domain/models/expense.dart';
import '../../analytics/presentation/providers/analytics_provider.dart';

class ExcelExportService {
  // ─── Color Palette (matching the reference template) ───────────────────────
  static final _purple    = ExcelColor.fromHexString('#6C63FF');
  static final _blue      = ExcelColor.fromHexString('#2196F3');
  static final _green     = ExcelColor.fromHexString('#4CAF50');
  static final _orange    = ExcelColor.fromHexString('#FF9800');
  static final _red       = ExcelColor.fromHexString('#F44336');
  static final _darkGray  = ExcelColor.fromHexString('#455A64');
  static final _darkBlue  = ExcelColor.fromHexString('#1A237E');
  static final _yellow    = ExcelColor.fromHexString('#FFF176');
  static final _white     = ExcelColor.fromHexString('#FFFFFF');

  static Future<void> exportToExcel({
    required List<Expense> expenses,
    required AnalyticsData analytics,
    String? userName,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Expense Tracker'];
    excel.delete('Sheet1');

    final fmt = DateFormat('dd-MM-yyyy');
    final now = DateTime.now();
    final monthName = DateFormat('MMMM yyyy').format(now);

    int row = 0;

    // ─────────────────────────────────────────────────────────────────────────
    // HEADER BANNER
    // ─────────────────────────────────────────────────────────────────────────
    _writeRow(sheet, row++, ['PERSONAL EXPENSE TRACKER'], bg: _purple, fg: _white, bold: true, fontSize: 16, mergeEnd: 5);
    _writeRow(sheet, row++, ['User Name:', userName ?? 'Guest', '', 'Month:', monthName], bold: true);
    _writeRow(sheet, row++, []);

    // ─────────────────────────────────────────────────────────────────────────
    // SECTION 1: MESS EXPENSES (Blue)
    // ─────────────────────────────────────────────────────────────────────────
    _writeRow(sheet, row++, ['SECTION 1: MESS EXPENSES'], bg: _blue, fg: _white, bold: true, mergeEnd: 5);
    _writeRow(sheet, row++,
      ['Date', 'Food Item', 'Food Price (Rs.)', 'Extra Item', 'Extra Price (Rs.)', 'Total (Rs.)'],
      bg: _blue, fg: _white, bold: true,
    );

    final messExpenses = expenses.where((e) => e.category.toLowerCase().contains('mess')).toList();
    double messTotal = 0;

    for (final e in messExpenses) {
      final total = e.amount;
      messTotal += total;
      _writeRow(sheet, row++, [fmt.format(e.date), e.title, total, '-', 0.0, total]);
    }

    _writeRow(sheet, row++, ['TOTAL SPENDING (MESS)', '', '', '', '', messTotal],
        bg: _yellow, bold: true);
    _writeRow(sheet, row++, []);

    // ─────────────────────────────────────────────────────────────────────────
    // SECTION 2: OUTSIDE MESS SPENDING (Green & Orange)
    // ─────────────────────────────────────────────────────────────────────────
    _writeRow(sheet, row++, ['SECTION 2: OUTSIDE MESS SPENDING'], bg: _green, fg: _white, bold: true, mergeEnd: 5);

    // 2a: Outside Food (Green)
    _writeRow(sheet, row++, ['Date', 'Food Item', 'Price (Rs.)'], bg: _green, fg: _white, bold: true);
    final foodExpenses = expenses.where((e) =>
        e.category.toLowerCase().contains('food') ||
        e.category.toLowerCase().contains('outside')).toList();
    double foodTotal = 0;
    for (final e in foodExpenses) {
      foodTotal += e.amount;
      _writeRow(sheet, row++, [fmt.format(e.date), e.title, e.amount]);
    }

    // 2b: Shopping (Orange)
    _writeRow(sheet, row++, ['Date', 'Item Bought', 'Price (Rs.)'], bg: _orange, fg: _white, bold: true);
    final shoppingExpenses = expenses.where((e) =>
        e.category.toLowerCase().contains('shop') ||
        e.category.toLowerCase().contains('purchase') ||
        e.category.toLowerCase().contains('clothe')).toList();
    double shopTotal = 0;
    for (final e in shoppingExpenses) {
      shopTotal += e.amount;
      _writeRow(sheet, row++, [fmt.format(e.date), e.title, e.amount]);
    }

    _writeRow(sheet, row++, ['OUTSIDE TOTAL (Food + Shopping)', '', (foodTotal + shopTotal)],
        bg: _yellow, bold: true);
    _writeRow(sheet, row++, []);

    // ─────────────────────────────────────────────────────────────────────────
    // SECTION 3: RENT / BILLS / FEES (Purple)
    // ─────────────────────────────────────────────────────────────────────────
    _writeRow(sheet, row++, ['SECTION 3: RENT / BILLS / FEES'], bg: _purple, fg: _white, bold: true, mergeEnd: 2);
    _writeRow(sheet, row++, ['Category', 'Description', 'Amount (Rs.)'], bg: _purple, fg: _white, bold: true);

    final billCategories = ['Rent', 'Electricity Bill', 'Water Bill', 'Internet / WiFi', 'College Fees', 'Other Fees'];
    final billExpenses = expenses.where((e) =>
        e.category.toLowerCase().contains('rent') ||
        e.category.toLowerCase().contains('bill') ||
        e.category.toLowerCase().contains('fee') ||
        e.category.toLowerCase().contains('internet')).toList();

    double billTotal = 0;
    final matched = <String>{};
    for (final e in billExpenses) {
      billTotal += e.amount;
      matched.add(e.category);
      _writeRow(sheet, row++, [e.category, e.title, e.amount]);
    }
    // Fill blank rows for unused categories
    for (final cat in billCategories) {
      if (!matched.any((m) => m.toLowerCase().contains(cat.toLowerCase()))) {
        _writeRow(sheet, row++, [cat, '-', 0.0]);
      }
    }

    _writeRow(sheet, row++, ['BILLS TOTAL', '', billTotal], bg: _yellow, bold: true);
    _writeRow(sheet, row++, []);

    // ─────────────────────────────────────────────────────────────────────────
    // SECTION 4: FRIENDS / FESTIVAL PAYMENTS (Red)
    // ─────────────────────────────────────────────────────────────────────────
    _writeRow(sheet, row++, ['SECTION 4: FRIENDS / FESTIVAL / COLLEGE FEST PAYMENTS'], bg: _red, fg: _white, bold: true, mergeEnd: 3);
    _writeRow(sheet, row++, ['Date', 'Event / Festival', 'Paid For (Name)', 'Amount (Rs.)'], bg: _red, fg: _white, bold: true);

    final festExpenses = expenses.where((e) => e.isSplit && e.splitWith != null).toList();
    double festTotal = 0;
    for (final e in festExpenses) {
      festTotal += e.amount;
      _writeRow(sheet, row++, [fmt.format(e.date), e.title, e.splitWith ?? '-', e.amount]);
    }
    if (festExpenses.isEmpty) {
      _writeRow(sheet, row++, ['-', '-', '-', 0.0]);
    }
    _writeRow(sheet, row++, ['FRIENDS PAYMENTS TOTAL', '', '', festTotal], bg: _yellow, bold: true);
    _writeRow(sheet, row++, []);

    // ─────────────────────────────────────────────────────────────────────────
    // SECTION 5: DEBTS & BORROWING (Light Blue)
    // ─────────────────────────────────────────────────────────────────────────
    _writeRow(sheet, row++, ['SECTION 5: DEBTS & BORROWING TRACKER'], bg: _blue, fg: _white, bold: true, mergeEnd: 4);
    _writeRow(sheet, row++,
      ['Friend Name', 'Total Amount (Rs.)', 'Amount Remaining (Rs.)', 'Who Pays Whom', 'Status'],
      bg: _blue, fg: _white, bold: true,
    );
    _writeRow(sheet, row++, ['(You Owe Others)', analytics.youOweTotal, analytics.youOweTotal, 'You → Roommates', 'Pending']);
    _writeRow(sheet, row++, ['(Others Owe You)', analytics.othersOweTotal, analytics.othersOweTotal, 'Roommates → You', 'Pending']);
    _writeRow(sheet, row++, []);

    // ─────────────────────────────────────────────────────────────────────────
    // SECTION 6: MISCELLANEOUS (Dark Gray)
    // ─────────────────────────────────────────────────────────────────────────
    _writeRow(sheet, row++, ['SECTION 6: OTHERS / MISCELLANEOUS'], bg: _darkGray, fg: _white, bold: true, mergeEnd: 2);
    _writeRow(sheet, row++, ['Date', 'Description', 'Amount (Rs.)'], bg: _darkGray, fg: _white, bold: true);

    final usedCategories = {'mess', 'food', 'outside', 'shop', 'purchase', 'clothe', 'rent', 'bill', 'fee', 'internet'};
    final miscExpenses = expenses.where((e) {
      final cat = e.category.toLowerCase();
      return !usedCategories.any((u) => cat.contains(u)) && !e.isSplit;
    }).toList();
    double miscTotal = 0;
    for (final e in miscExpenses) {
      miscTotal += e.amount;
      _writeRow(sheet, row++, [fmt.format(e.date), e.title, e.amount]);
    }
    if (miscExpenses.isEmpty) _writeRow(sheet, row++, ['-', '-', 0.0]);
    _writeRow(sheet, row++, ['MISC TOTAL', '', miscTotal], bg: _yellow, bold: true);
    _writeRow(sheet, row++, []);

    // ─────────────────────────────────────────────────────────────────────────
    // SECTION 7: MONTHLY SUMMARY DASHBOARD (Dark Blue)
    // ─────────────────────────────────────────────────────────────────────────
    _writeRow(sheet, row++, ['MONTHLY SUMMARY DASHBOARD'], bg: _darkBlue, fg: _white, bold: true, mergeEnd: 1);
    _writeRow(sheet, row++, ['Category', 'Amount (Rs.)'], bg: _darkBlue, fg: _white, bold: true);
    _writeRow(sheet, row++, ['Mess Expenses', messTotal]);
    _writeRow(sheet, row++, ['Outside Food + Shopping', foodTotal + shopTotal]);
    _writeRow(sheet, row++, ['Rent / Bills / Fees', billTotal]);
    _writeRow(sheet, row++, ['Friends / Festival Payments', festTotal]);
    _writeRow(sheet, row++, ['Others / Miscellaneous', miscTotal]);
    final grandTotal = messTotal + foodTotal + shopTotal + billTotal + festTotal + miscTotal;
    _writeRow(sheet, row++, ['GRAND TOTAL', grandTotal], bg: _blue, fg: _white, bold: true);

    // ─────────────────────────────────────────────────────────────────────────
    // Save & Share
    // ─────────────────────────────────────────────────────────────────────────
    final bytes = excel.save();
    if (bytes == null) return;

    final dir = await getTemporaryDirectory();
    final filename = 'MessBuddy_${DateFormat('MMM_yyyy').format(now)}.xlsx';
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);

    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: 'Mess Buddy – Monthly Expense Tracker'),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────
  static void _writeRow(
    Sheet sheet,
    int rowIdx,
    List<dynamic> values, {
    ExcelColor? bg,
    ExcelColor? fg,
    bool bold = false,
    int fontSize = 11,
    int? mergeEnd,
  }) {
    final style = CellStyle(
      backgroundColorHex: bg ?? ExcelColor.none,
      fontColorHex: fg ?? ExcelColor.fromHexString('#000000'),
      bold: bold,
      fontSize: fontSize,
    );

    for (int col = 0; col < values.length; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIdx));
      final v = values[col];
      if (v is String) {
        cell.value = TextCellValue(v);
      } else if (v is int) {
        cell.value = IntCellValue(v);
      } else if (v is double) {
        cell.value = DoubleCellValue(v);
      }
      if (bg != null || bold || fg != null) {
        cell.cellStyle = style;
      }
    }

    if (mergeEnd != null && values.isNotEmpty) {
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx),
        CellIndex.indexByColumnRow(columnIndex: mergeEnd, rowIndex: rowIdx),
      );
    }
  }
}
