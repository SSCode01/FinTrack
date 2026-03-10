import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/money_transaction.dart';
import '../services/transaction_service.dart';
import '../utils/balance_utils.dart';
import '../utils/format_utils.dart';
import '../utils/categories.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _pdfAmount(double amount) {
    // PDF default fonts don't support ₹ symbol, use Rs. instead
    return 'Rs.${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        )}';
  }

  Future<void> _exportPdf(
      BuildContext context, List<MoneyTransaction> txns) async {
    final pdf = pw.Document();
    final user = FirebaseAuth.instance.currentUser;
    final now = DateTime.now();

    final unpaid = txns.where((t) => !t.isPaid).toList();
    final paid = txns.where((t) => t.isPaid).toList();
    final totalReceivable = unpaid
        .where((t) => t.isCredit)
        .fold<double>(0, (s, t) => s + t.amount);
    final totalPayable = unpaid
        .where((t) => !t.isCredit)
        .fold<double>(0, (s, t) => s + t.amount);
    final netBalance = totalReceivable - totalPayable;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
          // HEADER
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('FinTrack Report',
                      style: pw.TextStyle(
                          fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text(
                      'Generated: ${now.day}/${now.month}/${now.year}',
                      style: const pw.TextStyle(
                          fontSize: 11, color: PdfColors.grey600)),
                ],
              ),
              pw.Text(user?.displayName ?? user?.email ?? '',
                  style: const pw.TextStyle(
                      fontSize: 12, color: PdfColors.grey700)),
            ],
          ),

          pw.Divider(thickness: 1, color: PdfColors.grey400),
          pw.SizedBox(height: 12),

          // SUMMARY
          pw.Text('Summary',
              style: pw.TextStyle(
                  fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _pdfStatBox('Total Receivable',
                  _pdfAmount(totalReceivable), PdfColors.green800),
              _pdfStatBox('Total Payable',
                  _pdfAmount(totalPayable), PdfColors.red800),
              _pdfStatBox(
                  'Net Balance',
                  '${netBalance >= 0 ? '+' : ''}${_pdfAmount(netBalance)}',
                  netBalance >= 0 ? PdfColors.green800 : PdfColors.red800),
            ],
          ),

          pw.SizedBox(height: 20),

          // ACTIVE TRANSACTIONS
          if (unpaid.isNotEmpty) ...[
            pw.Text('Active Transactions',
                style: pw.TextStyle(
                    fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(1.5),
              },
              children: [
                pw.TableRow(
                  decoration:
                      const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _pdfCell('Person', isHeader: true),
                    _pdfCell('Note', isHeader: true),
                    _pdfCell('Amount', isHeader: true),
                    _pdfCell('Type', isHeader: true),
                  ],
                ),
                ...unpaid.map((t) => pw.TableRow(
                      children: [
                        _pdfCell(t.personName),
                        _pdfCell(t.note.isEmpty ? '-' : t.note),
                        _pdfCell(_pdfAmount(t.amount)),
                        _pdfCell(t.isCredit ? 'Owed to me' : 'I owe'),
                      ],
                    )),
              ],
            ),
            pw.SizedBox(height: 20),
          ],

          // SETTLED TRANSACTIONS
          if (paid.isNotEmpty) ...[
            pw.Text('Settled Transactions',
                style: pw.TextStyle(
                    fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(1.5),
              },
              children: [
                pw.TableRow(
                  decoration:
                      const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _pdfCell('Person', isHeader: true),
                    _pdfCell('Note', isHeader: true),
                    _pdfCell('Amount', isHeader: true),
                    _pdfCell('Date', isHeader: true),
                  ],
                ),
                ...paid.map((t) => pw.TableRow(
                      children: [
                        _pdfCell(t.personName),
                        _pdfCell(t.note.isEmpty ? '-' : t.note),
                        _pdfCell(_pdfAmount(t.amount)),
                        _pdfCell(
                            '${t.date.day}/${t.date.month}/${t.date.year}'),
                      ],
                    )),
              ],
            ),
          ],
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'FinTrack_Report_${now.day}_${now.month}_${now.year}.pdf',
    );
  }

  pw.Widget _pdfStatBox(String label, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label,
              style: const pw.TextStyle(
                  fontSize: 10, color: PdfColors.grey600)),
          pw.SizedBox(height: 4),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: color)),
        ],
      ),
    );
  }

  pw.Widget _pdfCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight:
              isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(
            color: Color(0xFFFBC02D),
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                  blurRadius: 4,
                  color: Colors.black38,
                  offset: Offset(0, 1))
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
            ),
          ),
        ),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A1628),
              Color(0xFF0D2137),
              Color(0xFF0A1F1A),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: StreamBuilder<List<MoneyTransaction>>(
          stream: TransactionService.transactionsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child:
                    CircularProgressIndicator(color: Color(0xFFFFD700)),
              );
            }

            final txns = snapshot.data ?? [];
            final allTxns = txns;
            final unpaid = txns.where((t) => !t.isPaid).toList();
            final paid = txns.where((t) => t.isPaid).toList();

            final totalReceivable = unpaid
                .where((t) => t.isCredit)
                .fold<double>(0, (s, t) => s + t.amount);
            final totalPayable = unpaid
                .where((t) => !t.isCredit)
                .fold<double>(0, (s, t) => s + t.amount);
            final netBalance = totalReceivable - totalPayable;

            // Group by person for chart
            final Map<String, double> byPerson = {};
            for (final t in unpaid) {
              byPerson[t.personName] =
                  (byPerson[t.personName] ?? 0) +
                      (t.isCredit ? t.amount : -t.amount);
            }
            final topPersons = byPerson.entries.toList()
              ..sort((a, b) => b.value.abs().compareTo(a.value.abs()));
            final chartData = topPersons.take(5).toList();

            return ListView(
              controller: _scrollController,
              padding: EdgeInsets.only(
                bottom: 100,
                top: MediaQuery.of(context).padding.top > 0 ? 0 : 8,
              ),
              children: [
                // GREETING
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Hello, ${user?.displayName?.split(' ').first ?? 'there'} 👋',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // NET BALANCE BIG CARD
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: netBalance >= 0
                            ? [
                                const Color(0xFF1B5E20),
                                const Color(0xFF0D3320)
                              ]
                            : [const Color(0xFF7B1F1F), const Color(0xFF4A0E0E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Net Balance',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 8),
                        Text(
                          '${netBalance >= 0 ? '+' : ''}${formatAmount(netBalance)}',
                          style: const TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          netBalance >= 0
                              ? 'Overall you are owed money'
                              : 'Overall you owe money',
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),

                // STATS ROW
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          label: 'To Receive',
                          value: formatAmount(totalReceivable),
                          icon: Icons.arrow_downward,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          label: 'To Pay',
                          value: formatAmount(totalPayable),
                          icon: Icons.arrow_upward,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ),

                // SECOND STATS ROW
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          label: 'Active',
                          value: '${unpaid.length} txns',
                          icon: Icons.pending_actions,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          label: 'Settled',
                          value: '${paid.length} txns',
                          icon: Icons.check_circle,
                          color: Colors.greenAccent,
                        ),
                      ),
                    ],
                  ),
                ),

                // CATEGORY BREAKDOWN CHART
                if (allTxns.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Spending by Category',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                          const SizedBox(height: 16),
                          Builder(builder: (_) {
                            // Group by category
                            final Map<String, double> byCategory = {};
                            for (final t in allTxns) {
                              byCategory[t.category] =
                                  (byCategory[t.category] ?? 0) +
                                      t.amount;
                            }
                            final entries = byCategory.entries.toList()
                              ..sort((a, b) =>
                                  b.value.compareTo(a.value));

                            return Column(
                              children: [
                                SizedBox(
                                  height: 180,
                                  child: PieChart(
                                    PieChartData(
                                      sectionsSpace: 3,
                                      centerSpaceRadius: 36,
                                      sections: entries.map((e) {
                                        final cat =
                                            getCategoryByName(e.key);
                                        return PieChartSectionData(
                                          value: e.value,
                                          color: cat.color,
                                          title: cat.name
                                              .split(' ')
                                              .first,
                                          titleStyle: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight:
                                                  FontWeight.bold),
                                          radius: 60,
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                // LEGEND
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 8,
                                  children: entries.map((e) {
                                    final cat =
                                        getCategoryByName(e.key);
                                    return Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                              color: cat.color,
                                              shape: BoxShape.circle),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${cat.name.split(' ').first} (${formatAmount(e.value)})',
                                          style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 11),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                  ),

                // CALENDAR
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: _TransactionCalendar(
                    allTxns: allTxns,
                    parentScrollController: _scrollController,
                  ),
                ),

                // EXPORT PDF BUTTON
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: ElevatedButton.icon(
                    onPressed: txns.isEmpty
                        ? null
                        : () => _exportPdf(context, txns),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.picture_as_pdf,
                        color: Color(0xFFFFD700)),
                    label: const Text(
                      'Export to PDF',
                      style: TextStyle(
                        color: Color(0xFFFFD700),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.2),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
            width: 12,
            height: 12,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label,
            style:
                const TextStyle(color: Colors.white60, fontSize: 12)),
      ],
    );
  }
}

class _CalendarLegend extends StatelessWidget {
  final Color color;
  final String label;
  const _CalendarLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }
}

// ── Isolated calendar widget — only this rebuilds on date tap ──────────────
class _TransactionCalendar extends StatefulWidget {
  final List<MoneyTransaction> allTxns;
  final ScrollController parentScrollController;
  const _TransactionCalendar({
    required this.allTxns,
    required this.parentScrollController,
  });

  @override
  State<_TransactionCalendar> createState() => _TransactionCalendarState();
}

class _TransactionCalendarState extends State<_TransactionCalendar> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Future<void> _pickYear(BuildContext context) async {
    final currentYear = _focusedDay.year;
    final years = List.generate(
      currentYear - 1899,
      (i) => currentYear - i,
    );

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: 320,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1F2D),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: const Color(0xFFFFD700).withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Select Year',
                  style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: years.length,
                itemBuilder: (ctx, i) {
                  final year = years[i];
                  final isSelected = year == currentYear;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.pop(ctx);
                      setState(() {
                        _focusedDay = DateTime(year, _focusedDay.month, 1);
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFFFD700).withOpacity(0.15)
                            : Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFFFD700).withOpacity(0.5)
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$year',
                            style: TextStyle(
                              color: isSelected
                                  ? const Color(0xFFFFD700)
                                  : Colors.white70,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 16,
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle,
                                color: Color(0xFFFFD700), size: 18),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<DateTime, List<MoneyTransaction>> events = {};
    for (final t in widget.allTxns) {
      final day = DateTime(t.date.year, t.date.month, t.date.day);
      events.putIfAbsent(day, () => []).add(t);
    }

    final selectedTxns = _selectedDay == null
        ? <MoneyTransaction>[]
        : widget.allTxns.where((t) {
            final d = DateTime(t.date.year, t.date.month, t.date.day);
            return d == DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
          }).toList();

    return _ScrollPassthrough(
      scrollController: widget.parentScrollController,
      child: Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Text('Transaction Calendar',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 6, 16, 8),
            child: Row(
              children: [
                _CalendarLegend(color: Colors.greenAccent, label: 'Money in'),
                SizedBox(width: 16),
                _CalendarLegend(color: Colors.redAccent, label: 'Money out'),
                SizedBox(width: 16),
                _CalendarLegend(color: Color(0xFFFFD700), label: 'Both'),
              ],
            ),
          ),

          TableCalendar<MoneyTransaction>(
            firstDay: DateTime.utc(1900, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            pageJumpingEnabled: true,
            eventLoader: (day) {
              final key = DateTime(day.year, day.month, day.day);
              return events[key] ?? [];
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              setState(() => _focusedDay = focusedDay);
            },
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              defaultTextStyle: const TextStyle(color: Colors.white70),
              weekendTextStyle: const TextStyle(color: Colors.white54),
              selectedTextStyle: const TextStyle(
                  color: Colors.black, fontWeight: FontWeight.bold),
              selectedDecoration: const BoxDecoration(
                color: Color(0xFFFFD700),
                shape: BoxShape.circle,
              ),
              todayTextStyle: const TextStyle(
                  color: Color(0xFFFFD700), fontWeight: FontWeight.bold),
              todayDecoration: BoxDecoration(
                border: Border.all(
                    color: const Color(0xFFFFD700), width: 1.5),
                shape: BoxShape.circle,
              ),
              outsideTextStyle: const TextStyle(color: Colors.white24),
              markersMaxCount: 0,
              cellMargin: const EdgeInsets.all(4),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white70),
              rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white70),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(color: Colors.white54, fontSize: 12),
              weekendStyle: TextStyle(color: Colors.white38, fontSize: 12),
            ),
            calendarBuilders: CalendarBuilders(
              headerTitleBuilder: (context, day) {
                const months = [
                  "January", "February", "March", "April",
                  "May", "June", "July", "August",
                  "September", "October", "November", "December"
                ];
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "${months[day.month - 1]} ",
                      style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
                    GestureDetector(
                      onTap: () => _pickYear(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "${day.year}",
                              style: const TextStyle(
                                  color: Color(0xFFFFD700),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_drop_down,
                                color: Color(0xFFFFD700), size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
              markerBuilder: (context, day, dayEvents) {
                if (dayEvents.isEmpty) return const SizedBox();
                final hasCredit = dayEvents.any((t) => t.isCredit);
                final hasDebit = dayEvents.any((t) => !t.isCredit);
                final dotColor = (hasCredit && hasDebit)
                    ? const Color(0xFFFFD700)
                    : hasCredit
                        ? Colors.greenAccent
                        : Colors.redAccent;
                return Positioned(
                  bottom: 4,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                        color: dotColor, shape: BoxShape.circle),
                  ),
                );
              },
            ),
          ),

          // SELECTED DAY TRANSACTIONS
          if (_selectedDay != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Text(
                selectedTxns.isEmpty
                    ? 'No transactions on ${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}'
                    : '${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year} — ${selectedTxns.length} transaction${selectedTxns.length > 1 ? 's' : ''}',
                style: TextStyle(
                  color: selectedTxns.isEmpty
                      ? Colors.white38
                      : const Color(0xFFFFD700),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            if (selectedTxns.isNotEmpty)
              SizedBox(
                height: selectedTxns.length == 1
                    ? 72
                    : selectedTxns.length == 2
                        ? 144
                        : 220, // fixed height, scrollable inside
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 12),
                  physics: const BouncingScrollPhysics(),
                  itemCount: selectedTxns.length,
                  itemBuilder: (context, i) {
                    final t = selectedTxns[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 3),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: t.isCredit
                                ? Colors.greenAccent.withOpacity(0.3)
                                : Colors.redAccent.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              t.isCredit
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              color: t.isCredit
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                              size: 16,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t.personName,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                  if (t.note.isNotEmpty)
                                    Text(t.note,
                                        style: const TextStyle(
                                            color: Colors.white38,
                                            fontSize: 11)),
                                ],
                              ),
                            ),
                            Text(
                              '${t.isCredit ? '+' : '-'}${formatAmount(t.amount)}',
                              style: TextStyle(
                                color: t.isCredit
                                    ? Colors.greenAccent
                                    : Colors.redAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ],
      ),
    ), // Container
    ); // _ScrollPassthrough
  }
}

// Passes vertical scroll gestures up to the parent ListView
class _ScrollPassthrough extends StatelessWidget {
  final Widget child;
  final ScrollController scrollController;
  const _ScrollPassthrough({
    required this.child,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerMove: (event) {
        if (event.delta.dy.abs() > event.delta.dx.abs()) {
          if (scrollController.hasClients) {
            final current = scrollController.offset;
            final newOffset = (current - event.delta.dy)
                .clamp(0.0, scrollController.position.maxScrollExtent);
            scrollController.jumpTo(newOffset);
          }
        }
      },
      child: child,
    );
  }
}
