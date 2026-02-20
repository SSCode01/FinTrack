import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../utils/format_utils.dart';
import '../models/money_transaction.dart';
import '../services/transaction_service.dart';
import 'add_transaction_screen.dart';
import 'search_screen.dart';
import 'split_bill_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Group transactions by date label
  Map<String, List<MoneyTransaction>> _groupByDate(
      List<MoneyTransaction> txns) {
    final Map<String, List<MoneyTransaction>> grouped = {};
    final now = DateTime.now();

    for (final t in txns) {
      final diff = DateTime(now.year, now.month, now.day)
          .difference(DateTime(t.date.year, t.date.month, t.date.day))
          .inDays;

      String label;
      if (diff == 0) {
        label = 'Today';
      } else if (diff == 1) {
        label = 'Yesterday';
      } else if (diff <= 7) {
        label = 'This Week';
      } else if (diff <= 30) {
        label = 'This Month';
      } else {
        label = 'Older';
      }

      grouped.putIfAbsent(label, () => []).add(t);
    }
    return grouped;
  }

  Future<void> _markAsPaid(MoneyTransaction txn) async {
    HapticFeedback.mediumImpact();
    final updated = MoneyTransaction(
      id: txn.id,
      personName: txn.personName,
      amount: txn.amount,
      isCredit: txn.isCredit,
      note: txn.note,
      date: txn.date,
      isPaid: true,
    );
    await TransactionService.updateTransaction(updated);
  }

  Color _avatarColor(String name) {
    final colors = [
      Colors.purple,
      Colors.blue,
      Colors.teal,
      Colors.orange,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
      Colors.amber,
    ];
    return colors[name.codeUnitAt(0) % colors.length];
  }

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';

  @override
  Widget build(BuildContext context) {
    const sectionOrder = [
      'Today',
      'Yesterday',
      'This Week',
      'This Month',
      'Older'
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Transactions',
          style: TextStyle(
            color: Color(0xFFFBC02D),
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                  blurRadius: 4,
                  color: Colors.black38,
                  offset: Offset(0, 1)),
            ],
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32).withOpacity(0.85),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            tooltip: 'Search',
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            },
          ),
        ],
      ),

      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 72),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // SPLIT BILL FAB
            FloatingActionButton.small(
              heroTag: 'split',
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SplitBillScreen()),
                );
              },
              backgroundColor: const Color(0xFF1B5E20),
              child: const Icon(Icons.call_split, color: Color(0xFFFFD700)),
            ),
            const SizedBox(height: 8),
            // ADD TRANSACTION FAB
            FloatingActionButton(
              heroTag: 'add',
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AddTransactionScreen()),
                );
              },
              backgroundColor: const Color(0xFF1B5E20),
              child: const Icon(Icons.add, color: Color(0xFFFFD700)),
            ),
          ],
        ),
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

            final transactions = (snapshot.data ?? [])
                .where((t) => !t.isPaid)
                .toList()
              ..sort((a, b) => b.date.compareTo(a.date));

            if (transactions.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long,
                        color: Colors.white24, size: 72),
                    const SizedBox(height: 16),
                    const Text('No active transactions',
                        style: TextStyle(
                            color: Colors.white60, fontSize: 18)),
                    const SizedBox(height: 8),
                    const Text('Tap + to add one',
                        style: TextStyle(
                            color: Colors.white38, fontSize: 13)),
                  ],
                ),
              );
            }

            final grouped = _groupByDate(transactions);

            return ListView(
              padding: const EdgeInsets.only(bottom: 120, top: 8),
              children: [
                for (final section in sectionOrder)
                  if (grouped.containsKey(section)) ...[
                    // DATE SEPARATOR
                    _dateSeparator(section),

                    // TRANSACTIONS
                    ...grouped[section]!.map((txn) =>
                        _transactionTile(context, txn)),
                  ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _dateSeparator(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1B5E20),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: const Color(0xFFFFD700).withOpacity(0.4)),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(
              color: Colors.white.withOpacity(0.15),
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _transactionTile(BuildContext context, MoneyTransaction txn) {
    final initials = txn.personName.trim().isNotEmpty
        ? txn.personName.trim()[0].toUpperCase()
        : '?';
    final avatarColor = _avatarColor(txn.personName);

    return Slidable(
      key: ValueKey(txn.id),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddTransactionScreen(existingTxn: txn),
                ),
              );
            },
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Edit',
          ),
          SlidableAction(
            onPressed: (_) async {
              HapticFeedback.heavyImpact();
              await TransactionService.deleteTransaction(txn.id);
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.55),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: txn.isCredit
                ? Colors.green.withOpacity(0.25)
                : Colors.red.withOpacity(0.25),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            ListTile(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddTransactionScreen(existingTxn: txn),
                  ),
                );
              },
              contentPadding:
                  const EdgeInsets.fromLTRB(12, 8, 12, 0),
              leading: CircleAvatar(
                backgroundColor: avatarColor,
                radius: 22,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      txn.personName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Text(
                    '${txn.isCredit ? '+' : '-'}${formatAmount(txn.amount)}',
                    style: TextStyle(
                      color: txn.isCredit
                          ? Colors.greenAccent
                          : Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        txn.note.isNotEmpty
                            ? txn.note
                            : 'No note',
                        style: TextStyle(
                          color: txn.note.isNotEmpty
                              ? Colors.white70
                              : Colors.white30,
                          fontSize: 12,
                          fontStyle: txn.note.isEmpty
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(txn.date),
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),

            // BOTTOM ROW — type label + mark as paid button
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // TYPE CHIP
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: txn.isCredit
                          ? Colors.green.withOpacity(0.12)
                          : Colors.red.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      txn.isCredit ? 'They owe me' : 'I owe them',
                      style: TextStyle(
                        color: txn.isCredit
                            ? Colors.greenAccent
                            : Colors.redAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  // MARK AS PAID BUTTON
                  GestureDetector(
                    onTap: () async {
                      HapticFeedback.mediumImpact();
                      await _markAsPaid(txn);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                '${txn.personName} marked as paid!'),
                            backgroundColor: const Color(0xFF2E7D32),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.fromLTRB(
                                16, 0, 16, 80),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color:
                                Colors.greenAccent.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.check_circle_outline,
                              color: Colors.greenAccent, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Mark Paid',
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
