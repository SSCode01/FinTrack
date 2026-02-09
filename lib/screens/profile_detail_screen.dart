import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/format_utils.dart';
import '../models/money_transaction.dart';
import '../utils/balance_utils.dart';

class ProfileDetailScreen extends StatelessWidget {
  final String personName;

  const ProfileDetailScreen({super.key, required this.personName});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<MoneyTransaction>('transactionsBox');

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Profiles',
          style: TextStyle(
            color: Color(0xFFFFD700), // Gold
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        backgroundColor: const Color(0xFF2E7D32), // 🔥 FORCE GREEN
        elevation: 0,
      ),

      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bgim.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: ValueListenableBuilder(
          valueListenable: box.listenable(),
          builder: (context, Box<MoneyTransaction> b, _) {
            final txns = b.values
                .where((t) => t.personName == personName)
                .toList()
              ..sort((a, b) => b.date.compareTo(a.date));

            final balance = calculateBalance(txns);

            return Column(
              children: [
                // Balance header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Balance: ${balance >= 0 ? '+' : '-'}₹${balance.abs().toStringAsFixed(0)}',
                    style: TextStyle(
                      color:
                      balance >= 0 ? Colors.green : Colors.redAccent,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Transactions
                Expanded(
                  child: txns.isEmpty
                      ? const Center(
                    child: Text(
                      'No transactions',
                      style: TextStyle(
                          color: Colors.white, fontSize: 16),
                    ),
                  )
                      : ListView.builder(
                    itemCount: txns.length,
                    itemBuilder: (context, index) {
                      final t = txns[index];
                      return Card(
                        color: Colors.black.withOpacity(0.55),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: t.isCredit
                                ? Colors.green
                                : Colors.red,
                            child: Icon(
                              t.isCredit
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            t.note,
                            style:
                            const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            '${t.date.day}/${t.date.month}/${t.date.year}',
                            style: const TextStyle(
                                color: Colors.white70),
                          ),
                          trailing: Text(
                            '${t.isCredit ? '+' : '-'}${formatAmount(t.amount)}',
                            style: TextStyle(
                              color: t.isCredit
                                  ? Colors.green
                                  : Colors.redAccent,
                              fontWeight: FontWeight.bold,
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
    );
  }
}
