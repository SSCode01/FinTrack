import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/format_utils.dart';
import '../utils/categories.dart';
import '../utils/toast.dart';
import '../widgets/glass_card.dart';
import '../widgets/animated_list_item.dart';
import '../models/money_transaction.dart';
import '../services/transaction_service.dart';
import 'add_transaction_screen.dart';
import 'search_screen.dart';
import 'split_bill_screen.dart';
import 'transaction_action_sheet.dart';

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

            final transactions = (snapshot.data ?? [])
                .where((t) => !t.isPaid)
                .toList()
              ..sort((a, b) => b.date.compareTo(a.date));

            if (transactions.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Illustrated wallet SVG
                      SizedBox(
                        width: 160,
                        height: 140,
                        child: CustomPaint(painter: _EmptyWalletPainter()),
                      ),
                      const SizedBox(height: 24),
                      const Text('All settled up!',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      const Text(
                          'No active transactions yet.\nTap + to record who owes you\nor who you owe.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white38,
                              fontSize: 14,
                              height: 1.6)),
                      const SizedBox(height: 28),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFFFFD700).withOpacity(0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_circle_outline,
                                color: Color(0xFFFFD700), size: 16),
                            SizedBox(width: 8),
                            Text('Add your first transaction',
                                style: TextStyle(
                                    color: Color(0xFFFFD700),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final grouped = _groupByDate(transactions);
            int globalIndex = 0;

            return ListView(
              padding: const EdgeInsets.only(bottom: 120, top: 8),
              children: [
                for (final section in sectionOrder)
                  if (grouped.containsKey(section)) ...[
                    _dateSeparator(section),
                    ...grouped[section]!.map((txn) {
                      final tile = AnimatedListItem(
                        index: globalIndex,
                        child: _transactionTile(context, txn),
                      );
                      globalIndex++;
                      return tile;
                    }),
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

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddTransactionScreen(existingTxn: txn),
          ),
        );
      },
      onLongPress: () => showTransactionActions(context, txn),
      child: GlassCard(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        borderColor: txn.isCredit
            ? Colors.green.withOpacity(0.3)
            : Colors.red.withOpacity(0.3),
        child: Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
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
                        txn.note.isNotEmpty ? txn.note : 'No note',
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

            // BOTTOM ROW
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // TYPE CHIP
                  Row(
                    children: [
                      // CATEGORY CHIP
                      Builder(builder: (_) {
                        final cat = getCategoryByName(txn.category);
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: cat.color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Icon(cat.icon, color: cat.color, size: 11),
                              const SizedBox(width: 4),
                              Text(
                                cat.name.split(' ').first,
                                style: TextStyle(
                                    color: cat.color,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: txn.isCredit
                              ? Colors.green.withOpacity(0.12)
                              : Colors.red.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          txn.isCredit ? 'Owed to me' : 'I owe',
                          style: TextStyle(
                            color: txn.isCredit
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // HINT + MARK AS PAID
                  Row(
                    children: [
                      const Text('Hold to edit  ',
                          style: TextStyle(
                              color: Colors.white24, fontSize: 10)),
                      GestureDetector(
                        onTap: () async {
                          HapticFeedback.mediumImpact();
                          await _markAsPaid(txn);
                          if (context.mounted) {
                            showToast(
                              context,
                              message: '${txn.personName}\nMarked Paid!',
                              type: ToastType.success,
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
                                color: Colors.greenAccent.withOpacity(0.4)),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyWalletPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Wallet body
    final walletPaint = Paint()
      ..color = const Color(0xFF1B3A4B)
      ..style = PaintingStyle.fill;
    final walletRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.1, h * 0.2, w * 0.8, h * 0.65),
        const Radius.circular(18));
    canvas.drawRRect(walletRect, walletPaint);

    // Wallet top flap
    final flapPaint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..style = PaintingStyle.fill;
    final flapRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.1, h * 0.15, w * 0.8, h * 0.2),
        const Radius.circular(14));
    canvas.drawRRect(flapRect, flapPaint);

    // Card slot
    final cardPaint = Paint()
      ..color = const Color(0xFF0D2137)
      ..style = PaintingStyle.fill;
    final cardRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.2, h * 0.45, w * 0.6, h * 0.22),
        const Radius.circular(8));
    canvas.drawRRect(cardRect, cardPaint);

    // Card stripe
    final stripePaint = Paint()
      ..color = const Color(0xFFFFD700).withOpacity(0.6)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(w * 0.2, h * 0.52, w * 0.6, h * 0.05),
        stripePaint);

    // Coin stack — 3 coins
    for (int i = 2; i >= 0; i--) {
      final coinPaint = Paint()
        ..color = i == 0
            ? const Color(0xFFFFD700)
            : const Color(0xFFFFD700).withOpacity(0.5 + i * 0.15)
        ..style = PaintingStyle.fill;
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(w * 0.72, h * 0.3 + i * 4),
              width: w * 0.18,
              height: w * 0.08),
          coinPaint);
    }

    // Dollar sign on top coin
    final textPainter = TextPainter(
      text: const TextSpan(
          text: '₹',
          style: TextStyle(
              color: Colors.black,
              fontSize: 11,
              fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
        canvas, Offset(w * 0.72 - 5, h * 0.26));

    // Sparkle dots around
    final sparklePaint = Paint()
      ..color = const Color(0xFFFFD700).withOpacity(0.4)
      ..style = PaintingStyle.fill;
    for (final pos in [
      Offset(w * 0.15, h * 0.12),
      Offset(w * 0.85, h * 0.18),
      Offset(w * 0.08, h * 0.55),
      Offset(w * 0.92, h * 0.6),
    ]) {
      canvas.drawCircle(pos, 3, sparklePaint);
    }
  }

  @override
  bool shouldRepaint(_EmptyWalletPainter oldDelegate) => false;
}
