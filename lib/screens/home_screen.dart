import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../utils/format_utils.dart';
import '../models/money_transaction.dart';
import 'add_transaction_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final transactionsBox = Hive.box<MoneyTransaction>('transactionsBox');

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Recent Transactions',
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



      // ➕ ADD TRANSACTION
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddTransactionScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
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
                  hintText: 'Search transactions',
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

            // 📜 TRANSACTIONS LIST
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: transactionsBox.listenable(),
                builder: (context, Box<MoneyTransaction> box, _) {
                  final query = _searchController.text.toLowerCase();

                  final transactions = box.values
                      .where((txn) =>
                  txn.personName.toLowerCase().contains(query) ||
                      txn.note.toLowerCase().contains(query))
                      .toList()
                    ..sort((a, b) => b.date.compareTo(a.date));

                  if (transactions.isEmpty) {
                    return const Center(
                      child: Text(
                        'No transactions yet',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final txn = transactions[index];

                      return Slidable(
                        key: ValueKey(txn.key),

                        // 👉 SLIDE ACTIONS
                        endActionPane: ActionPane(
                          motion: const ScrollMotion(),
                          children: [
                            // ✏ EDIT
                            SlidableAction(
                              onPressed: (_) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        AddTransactionScreen(existingTxn: txn),
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

                        // 👉 TRANSACTION CARD
                        child: Card(
                          color: Colors.black.withOpacity(0.55),
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                              txn.isCredit ? Colors.green : Colors.red,
                              child: Icon(
                                txn.isCredit
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              txn.personName,
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              '${txn.note} • ${_formatDate(txn.date)}',
                              style:
                              const TextStyle(color: Colors.white70),
                            ),
                            trailing: Text(
                              '${txn.isCredit ? '+' : '-'}${formatAmount(txn.amount)}',
                              style: TextStyle(
                                color: txn.isCredit
                                    ? Colors.green
                                    : Colors.redAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
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
