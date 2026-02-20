import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/money_transaction.dart';
import '../services/transaction_service.dart';
import '../utils/balance_utils.dart';
import '../utils/format_utils.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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
        backgroundColor: const Color(0xFF2E7D32).withOpacity(0.85),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bgim.jpg'),
            fit: BoxFit.cover,
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
              padding: const EdgeInsets.only(bottom: 120),
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
                                const Color(0xFF2E7D32),
                                const Color(0xFF1B5E20)
                              ]
                            : [Colors.red.shade800, Colors.red.shade900],
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

                // PIE CHART
                if (unpaid.isNotEmpty && totalReceivable + totalPayable > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Receivable vs Payable',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 180,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 3,
                                centerSpaceRadius: 40,
                                sections: [
                                  if (totalReceivable > 0)
                                    PieChartSectionData(
                                      value: totalReceivable,
                                      color: Colors.green,
                                      title: 'Receive',
                                      titleStyle: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold),
                                      radius: 60,
                                    ),
                                  if (totalPayable > 0)
                                    PieChartSectionData(
                                      value: totalPayable,
                                      color: Colors.redAccent,
                                      title: 'Pay',
                                      titleStyle: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold),
                                      radius: 60,
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _legendDot(Colors.green, 'To Receive'),
                              const SizedBox(width: 20),
                              _legendDot(Colors.redAccent, 'To Pay'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                // BAR CHART - TOP PERSONS
                if (chartData.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Top Outstanding Balances',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 200,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: chartData
                                    .map((e) => e.value.abs())
                                    .reduce((a, b) => a > b ? a : b) *
                                    1.2,
                                barTouchData:
                                    BarTouchData(enabled: false),
                                titlesData: FlTitlesData(
                                  leftTitles: const AxisTitles(
                                      sideTitles:
                                          SideTitles(showTitles: false)),
                                  rightTitles: const AxisTitles(
                                      sideTitles:
                                          SideTitles(showTitles: false)),
                                  topTitles: const AxisTitles(
                                      sideTitles:
                                          SideTitles(showTitles: false)),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        final idx = value.toInt();
                                        if (idx >= chartData.length)
                                          return const SizedBox();
                                        final name =
                                            chartData[idx].key;
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                              top: 4),
                                          child: Text(
                                            name.length > 6
                                                ? '${name.substring(0, 6)}...'
                                                : name,
                                            style: const TextStyle(
                                                color: Colors.white60,
                                                fontSize: 10),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                gridData:
                                    const FlGridData(show: false),
                                borderData: FlBorderData(show: false),
                                barGroups: chartData
                                    .asMap()
                                    .entries
                                    .map((e) => BarChartGroupData(
                                          x: e.key,
                                          barRods: [
                                            BarChartRodData(
                                              toY: e.value.value.abs(),
                                              color: e.value.value >= 0
                                                  ? Colors.green
                                                  : Colors.redAccent,
                                              width: 20,
                                              borderRadius:
                                                  const BorderRadius.vertical(
                                                      top: Radius.circular(6)),
                                            ),
                                          ],
                                        ))
                                    .toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
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
        color: Colors.black.withOpacity(0.55),
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
