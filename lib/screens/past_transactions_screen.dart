import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../utils/format_utils.dart';
import '../models/money_transaction.dart';
import 'add_transaction_screen.dart';

class PastTransactionsScreen extends StatefulWidget {
  const PastTransactionsScreen({super.key});

  @override
  State<PastTransactionsScreen> createState() =>
      _PastTransactionsScreenState();
}

class _PastTransactionsScreenState extends State<PastTransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final transactionsBox = Hive.box<MoneyTransaction>('transactionsBox');

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Past Transactions',
          style: TextStyle(
            color: Color(0xFFFBC02D),
            shadows: [
              Shadow(
                blurRadius: 4,
                color: Colors.black38,
                offset: Offset(0, 1),
              ),
            ],
            fontWeight: FontWeight.bold,
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
        child: Column(
          children: [
            // 🔍 SEARCH BAR
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search past transactions',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // SUMMARY BANNER
            ValueListenableBuilder(
              valueListenable: transactionsBox.listenable(),
              builder: (context, Box<MoneyTransaction> box, _) {
                final paid = box.values.where((t) => t.isPaid).toList();
                final totalPaid = paid.fold<double>(
                    0, (sum, t) => sum + t.amount);

                return Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.greenAccent.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: Colors.greenAccent, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            '${paid.length} settled transaction${paid.length == 1 ? '' : 's'}',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                      Text(
                        formatAmount(totalPaid),
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 4),

            // 📜 PAID TRANSACTIONS LIST
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: transactionsBox.listenable(),
                builder: (context, Box<MoneyTransaction> box, _) {
                  final query = _searchController.text.toLowerCase();

                  final transactions = box.values
                      .where((txn) =>
                          txn.isPaid &&
                          (txn.personName.toLowerCase().contains(query) ||
                              txn.note.toLowerCase().contains(query)))
                      .toList()
                    ..sort((a, b) => b.date.compareTo(a.date));

                  if (transactions.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.history,
                              color: Colors.white38, size: 64),
                          const SizedBox(height: 12),
                          const Text(
                            'No settled transactions yet',
                            style: TextStyle(
                                color: Colors.white60, fontSize: 16),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Mark a transaction as Paid to see it here',
                            style: TextStyle(
                                color: Colors.white38, fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final txn = transactions[index];

                      return Slidable(
                        key: ValueKey(txn.key),
                        endActionPane: ActionPane(
                          motion: const ScrollMotion(),
                          children: [
                            // ✏ EDIT (can mark as unpaid again)
                            SlidableAction(
                              onPressed: (_) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AddTransactionScreen(
                                        existingTxn: txn),
                                  ),
                                );
                              },
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              icon: Icons.edit,
                              label: 'Edit',
                            ),

                            // 🗑 DELETE
                            SlidableAction(
                              onPressed: (_) {
                                txn.delete();
                              },
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              icon: Icons.delete,
                              label: 'Delete',
                            ),
                          ],
                        ),

                        child: Card(
                          color: Colors.black.withOpacity(0.45),
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          child: ListTile(
                            leading: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                CircleAvatar(
                                  backgroundColor: txn.isCredit
                                      ? Colors.green.withOpacity(0.6)
                                      : Colors.red.withOpacity(0.6),
                                  child: Icon(
                                    txn.isCredit
                                        ? Icons.arrow_downward
                                        : Icons.arrow_upward,
                                    color: Colors.white,
                                  ),
                                ),
                                Positioned(
                                  right: -4,
                                  bottom: -4,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.greenAccent,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(2),
                                    child: const Icon(
                                      Icons.check,
                                      size: 10,
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
                                        color: Colors.white70),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.greenAccent
                                        .withOpacity(0.15),
                                    borderRadius:
                                        BorderRadius.circular(6),
                                    border: Border.all(
                                        color: Colors.greenAccent
                                            .withOpacity(0.4)),
                                  ),
                                  child: const Text(
                                    'PAID',
                                    style: TextStyle(
                                      color: Colors.greenAccent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Text(
                              '${txn.note} • ${_formatDate(txn.date)}',
                              style: const TextStyle(
                                  color: Colors.white38),
                            ),
                            trailing: Text(
                              '${txn.isCredit ? '+' : '-'}${formatAmount(txn.amount)}',
                              style: TextStyle(
                                color: txn.isCredit
                                    ? Colors.green.withOpacity(0.7)
                                    : Colors.redAccent.withOpacity(0.7),
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
