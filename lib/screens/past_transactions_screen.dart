import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/money_transaction.dart';
import '../services/transaction_service.dart';
import '../utils/format_utils.dart';
import '../utils/categories.dart';
import 'transaction_action_sheet.dart';
import '../widgets/animated_list_item.dart';

class PastTransactionsScreen extends StatefulWidget {
  const PastTransactionsScreen({super.key});

  @override
  State<PastTransactionsScreen> createState() =>
      _PastTransactionsScreenState();
}

class _PastTransactionsScreenState extends State<PastTransactionsScreen> {
  String _search = '';
  String _selectedFlow = 'All'; // 'All', 'Received', 'Sent'
  String _selectedCategory = 'All';
  String _selectedTimeRange = 'All'; // 'All', 'This Week', 'This Month', 'This Year'

  final List<String> _flowOptions = const ['All', 'Received', 'Sent'];
  final List<String> _timeOptions = const ['All', 'This Week', 'This Month', 'This Year'];

  List<String> get _categoryOptions {
    return ['All', ...kCategories.map((c) => c.name)];
  }

  String _getDateGroup(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final itemDate = DateTime(date.year, date.month, date.day);

    if (itemDate == today) {
      return 'Today';
    } else if (itemDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMMM yyyy').format(date);
    }
  }

  void _showReceiptDialog(BuildContext context, MoneyTransaction txn) {
    final cat = getCategoryByName(txn.category);
    final formattedDate = DateFormat('MMMM dd, yyyy • hh:mm a').format(txn.date);
    
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0F1E36), Color(0xFF0A1628)],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cat.color.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: cat.color.withOpacity(0.3)),
                      ),
                      child: Icon(cat.icon, color: cat.color, size: 36),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      txn.personName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, color: Colors.greenAccent, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'FULLY SETTLED',
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '${txn.isCredit ? '+' : '-'}${formatAmount(txn.amount)}',
                      style: TextStyle(
                        color: txn.isCredit ? Colors.greenAccent : Colors.redAccent,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    CustomPaint(
                      size: const Size(double.infinity, 1),
                      painter: _DashedLinePainter(),
                    ),
                    const SizedBox(height: 24),
                    _buildReceiptRow('Type', txn.isCredit ? 'Received Inflow' : 'Paid Outflow'),
                    _buildReceiptRow('Category', txn.category),
                    _buildReceiptRow('Date & Time', formattedDate),
                    _buildReceiptRow('Note', txn.note.isNotEmpty ? txn.note : 'No note added'),
                    _buildReceiptRow('Transaction ID', txn.id, isId: true),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.07),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.white.withOpacity(0.12)),
                          ),
                          elevation: 0,
                        ),
                        child: const Text('Close Receipt', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isId = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: isId ? Colors.white30 : Colors.white70,
                fontSize: 12,
                fontWeight: isId ? FontWeight.normal : FontWeight.w500,
                fontFamily: isId ? 'monospace' : null,
                fontStyle: (!isId && label == 'Note' && value == 'No note added')
                    ? FontStyle.italic
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton({
    required String label,
    required String currentValue,
    required List<String> options,
    required ValueChanged<String> onSelected,
    required IconData icon,
  }) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      itemBuilder: (context) {
        return options.map((opt) {
          final isSelected = opt == currentValue;
          return PopupMenuItem<String>(
            value: opt,
            child: Row(
              children: [
                if (isSelected)
                  const Icon(Icons.check, size: 18, color: Color(0xFFFFD700))
                else
                  const SizedBox(width: 18),
                const SizedBox(width: 8),
                Text(
                  opt,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFFFFD700) : Colors.white,
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFF0F1E36),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: currentValue == 'All'
              ? Colors.white.withOpacity(0.05)
              : const Color(0xFFFFD700).withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: currentValue == 'All'
                ? Colors.white.withOpacity(0.1)
                : const Color(0xFFFFD700).withOpacity(0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: currentValue == 'All' ? Colors.white70 : const Color(0xFFFFD700),
            ),
            const SizedBox(width: 6),
            Text(
              currentValue == 'All' ? label : currentValue,
              style: TextStyle(
                color: currentValue == 'All' ? Colors.white70 : const Color(0xFFFFD700),
                fontSize: 12,
                fontWeight: currentValue == 'All' ? FontWeight.normal : FontWeight.bold,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: currentValue == 'All' ? Colors.white70 : const Color(0xFFFFD700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards({
    required double totalSettled,
    required double totalReceived,
    required double totalSent,
  }) {
    return Container(
      height: 76,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _buildStatCard(
              title: 'Total Settled',
              amount: totalSettled,
              color: const Color(0xFFFFD700),
              icon: Icons.account_balance_wallet_outlined,
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              title: 'Received (+)',
              amount: totalReceived,
              color: Colors.greenAccent,
              icon: Icons.arrow_downward,
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              title: 'Sent (-)',
              amount: totalSent,
              color: Colors.redAccent,
              icon: Icons.arrow_upward,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      width: 144,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
              Icon(icon, color: color.withOpacity(0.6), size: 14),
            ],
          ),
          Text(
            formatAmount(amount),
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Past Transactions',
          style: TextStyle(
            color: Color(0xFFFFD700),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.white.withOpacity(0.08),
            height: 1,
          ),
        ),
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
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                style: const TextStyle(color: Colors.white),
                cursorColor: const Color(0xFFFFD700),
                decoration: InputDecoration(
                  hintText: 'Search transactions...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (val) => setState(() => _search = val.toLowerCase().trim()),
              ),
            ),

            // Dynamic filter row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  _buildFilterButton(
                    label: 'Flow',
                    currentValue: _selectedFlow,
                    options: _flowOptions,
                    onSelected: (val) => setState(() => _selectedFlow = val),
                    icon: Icons.swap_vert,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterButton(
                    label: 'Category',
                    currentValue: _selectedCategory,
                    options: _categoryOptions,
                    onSelected: (val) => setState(() => _selectedCategory = val),
                    icon: Icons.category_outlined,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterButton(
                    label: 'Time',
                    currentValue: _selectedTimeRange,
                    options: _timeOptions,
                    onSelected: (val) => setState(() => _selectedTimeRange = val),
                    icon: Icons.access_time,
                  ),
                  if (_selectedFlow != 'All' || _selectedCategory != 'All' || _selectedTimeRange != 'All') ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white38, size: 20),
                      tooltip: 'Clear filters',
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        setState(() {
                          _selectedFlow = 'All';
                          _selectedCategory = 'All';
                          _selectedTimeRange = 'All';
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),

            // Firestore Data Stream Builder
            Expanded(
              child: StreamBuilder<List<MoneyTransaction>>(
                stream: TransactionService.transactionsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFFFFD700)),
                    );
                  }

                  // 1. Base filter for paid transactions
                  var paid = (snapshot.data ?? [])
                      .where((t) => t.isPaid)
                      .toList()
                    ..sort((a, b) => b.date.compareTo(a.date));

                  // 2. Search filtering
                  if (_search.isNotEmpty) {
                    paid = paid
                        .where((t) =>
                            t.personName.toLowerCase().contains(_search) ||
                            t.note.toLowerCase().contains(_search))
                        .toList();
                  }

                  // 3. Flow filtering
                  if (_selectedFlow == 'Received') {
                    paid = paid.where((t) => t.isCredit).toList();
                  } else if (_selectedFlow == 'Sent') {
                    paid = paid.where((t) => !t.isCredit).toList();
                  }

                  // 4. Category filtering
                  if (_selectedCategory != 'All') {
                    paid = paid.where((t) => t.category == _selectedCategory).toList();
                  }

                  // 5. Time range filtering
                  if (_selectedTimeRange != 'All') {
                    final now = DateTime.now();
                    paid = paid.where((t) {
                      if (_selectedTimeRange == 'This Week') {
                        final oneWeekAgo = now.subtract(const Duration(days: 7));
                        return t.date.isAfter(oneWeekAgo);
                      } else if (_selectedTimeRange == 'This Month') {
                        final startOfMonth = DateTime(now.year, now.month, 1);
                        return t.date.isAfter(startOfMonth);
                      } else if (_selectedTimeRange == 'This Year') {
                        final startOfYear = DateTime(now.year, 1, 1);
                        return t.date.isAfter(startOfYear);
                      }
                      return true;
                    }).toList();
                  }

                  // Recalculate summary stats dynamically based on filtered items
                  double totalSettled = 0;
                  double totalReceived = 0;
                  double totalSent = 0;
                  for (final txn in paid) {
                    totalSettled += txn.amount;
                    if (txn.isCredit) {
                      totalReceived += txn.amount;
                    } else {
                      totalSent += txn.amount;
                    }
                  }

                  // If empty list, display empty message
                  if (paid.isEmpty) {
                    return Column(
                      children: [
                        _buildStatsCards(
                          totalSettled: totalSettled,
                          totalReceived: totalReceived,
                          totalSent: totalSent,
                        ),
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.history, color: Colors.white24, size: 72),
                                const SizedBox(height: 16),
                                Text(
                                  _search.isNotEmpty ||
                                          _selectedFlow != 'All' ||
                                          _selectedCategory != 'All' ||
                                          _selectedTimeRange != 'All'
                                      ? 'No transactions match filters'
                                      : 'No past transactions yet',
                                  style: const TextStyle(color: Colors.white60, fontSize: 16),
                                ),
                                if (_search.isNotEmpty ||
                                    _selectedFlow != 'All' ||
                                    _selectedCategory != 'All' ||
                                    _selectedTimeRange != 'All') ...[
                                  const SizedBox(height: 12),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _search = '';
                                        _selectedFlow = 'All';
                                        _selectedCategory = 'All';
                                        _selectedTimeRange = 'All';
                                      });
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFFFFD700),
                                    ),
                                    child: const Text('Reset Filters'),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  // 6. Group transactions by date categories
                  final Map<String, List<MoneyTransaction>> grouped = {};
                  for (final txn in paid) {
                    final group = _getDateGroup(txn.date);
                    grouped.putIfAbsent(group, () => []).add(txn);
                  }

                  // Flatten grouping into linear items list
                  final List<dynamic> listItems = [];
                  grouped.forEach((groupName, txns) {
                    listItems.add(groupName);
                    listItems.addAll(txns);
                  });

                  return Column(
                    children: [
                      // Overview summary cards
                      _buildStatsCards(
                        totalSettled: totalSettled,
                        totalReceived: totalReceived,
                        totalSent: totalSent,
                      ),
                      // Scrollable transaction list
                      Expanded(
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 100, top: 4),
                          itemCount: listItems.length,
                          itemBuilder: (context, index) {
                            final item = listItems[index];

                            // If it's a date group header
                            if (item is String) {
                              return Padding(
                                padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                                child: Text(
                                  item,
                                  style: const TextStyle(
                                    color: Color(0xFFFFD700),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              );
                            }

                            // If it's a MoneyTransaction item
                            final txn = item as MoneyTransaction;
                            final cat = getCategoryByName(txn.category);

                            return AnimatedListItem(
                              index: index,
                              child: GestureDetector(
                                onTap: () => _showReceiptDialog(context, txn),
                                onLongPress: () => showTransactionActions(context, txn),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.04),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.08),
                                    ),
                                  ),
                                  child: ListTile(
                                    leading: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: cat.color.withOpacity(0.15),
                                          child: Icon(
                                            cat.icon,
                                            color: cat.color,
                                            size: 20,
                                          ),
                                        ),
                                        Positioned(
                                          right: -2,
                                          bottom: -2,
                                          child: Container(
                                            decoration: const BoxDecoration(
                                              color: Colors.greenAccent,
                                              shape: BoxShape.circle,
                                            ),
                                            padding: const EdgeInsets.all(2),
                                            child: const Icon(
                                              Icons.check,
                                              size: 8,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            txn.personName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        // Mini Category chip
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: cat.color.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: cat.color.withOpacity(0.25),
                                            ),
                                          ),
                                          child: Text(
                                            txn.category.toUpperCase(),
                                            style: TextStyle(
                                              color: cat.color,
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        txn.note.isNotEmpty ? txn.note : 'No note',
                                        style: const TextStyle(
                                          color: Colors.white38,
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    trailing: Text(
                                      '${txn.isCredit ? '+' : '-'}${formatAmount(txn.amount)}',
                                      style: TextStyle(
                                        color: txn.isCredit
                                            ? Colors.greenAccent
                                            : Colors.redAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 4.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
