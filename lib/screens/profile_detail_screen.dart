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
        title: Text(
          personName,
          style: const TextStyle(
            color: Color(0xFFFFD700),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
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
            final allTxns = b.values
                .where((t) => t.personName == personName)
                .toList()
              ..sort((a, b) => b.date.compareTo(a.date));

            final unpaidTxns =
                allTxns.where((t) => !t.isPaid).toList();
            final paidTxns = allTxns.where((t) => t.isPaid).toList();

            final outstandingBalance = calculateBalance(unpaidTxns);
            final totalBalance = calculateBalance(allTxns);

            return Column(
              children: [
                // BALANCE HEADER CARD
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _statBlock(
                        label: 'Outstanding',
                        value:
                            '${outstandingBalance >= 0 ? '+' : '-'}${formatAmount(outstandingBalance.abs())}',
                        color: outstandingBalance >= 0
                            ? Colors.green
                            : Colors.redAccent,
                      ),
                      Container(
                          width: 1,
                          height: 40,
                          color: Colors.white24),
                      _statBlock(
                        label: 'Total (all)',
                        value:
                            '${totalBalance >= 0 ? '+' : '-'}${formatAmount(totalBalance.abs())}',
                        color: Colors.white70,
                      ),
                      Container(
                          width: 1,
                          height: 40,
                          color: Colors.white24),
                      _statBlock(
                        label: 'Paid',
                        value: '${paidTxns.length}',
                        color: Colors.greenAccent,
                        suffix: ' txns',
                      ),
                    ],
                  ),
                ),

                // TRANSACTIONS
                Expanded(
                  child: allTxns.isEmpty
                      ? const Center(
                          child: Text(
                            'No transactions',
                            style: TextStyle(
                                color: Colors.white, fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          padding:
                              const EdgeInsets.only(bottom: 100),
                          itemCount: allTxns.length,
                          itemBuilder: (context, index) {
                            final t = allTxns[index];
                            return Card(
                              color: Colors.black.withOpacity(
                                  t.isPaid ? 0.35 : 0.55),
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              child: ListTile(
                                leading: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: (t.isCredit
                                              ? Colors.green
                                              : Colors.red)
                                          .withOpacity(
                                              t.isPaid ? 0.5 : 1.0),
                                      child: Icon(
                                        t.isCredit
                                            ? Icons.arrow_downward
                                            : Icons.arrow_upward,
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (t.isPaid)
                                      Positioned(
                                        right: -4,
                                        bottom: -4,
                                        child: Container(
                                          decoration:
                                              const BoxDecoration(
                                            color: Colors.greenAccent,
                                            shape: BoxShape.circle,
                                          ),
                                          padding:
                                              const EdgeInsets.all(2),
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
                                        t.note.isEmpty
                                            ? '(no note)'
                                            : t.note,
                                        style: TextStyle(
                                          color: t.isPaid
                                              ? Colors.white54
                                              : Colors.white,
                                        ),
                                      ),
                                    ),
                                    if (t.isPaid)
                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2),
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
                                  '${t.date.day}/${t.date.month}/${t.date.year}',
                                  style: TextStyle(
                                    color: t.isPaid
                                        ? Colors.white38
                                        : Colors.white70,
                                  ),
                                ),
                                trailing: Text(
                                  '${t.isCredit ? '+' : '-'}${formatAmount(t.amount)}',
                                  style: TextStyle(
                                    color: (t.isCredit
                                            ? Colors.green
                                            : Colors.redAccent)
                                        .withOpacity(
                                            t.isPaid ? 0.55 : 1.0),
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

  Widget _statBlock({
    required String label,
    required String value,
    required Color color,
    String suffix = '',
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$value$suffix',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style:
              const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }
}
