import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/money_transaction.dart';
import '../utils/balance_utils.dart';
import '../utils/format_utils.dart';
import 'profile_detail_screen.dart';

class ProfilesScreen extends StatelessWidget {
  const ProfilesScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B3A1F),
        title: const Text('Sign Out',
            style: TextStyle(color: Color(0xFFFFD700))),
        content: const Text('Are you sure you want to sign out?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent),
            child: const Text('Sign Out',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      // AuthGate will automatically redirect to LoginScreen
    }
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<MoneyTransaction>('transactionsBox');

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Profiles',
          style: TextStyle(
            color: Color(0xFFFFD700),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32).withOpacity(0.85),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout, color: Colors.white70),
            onPressed: () => _logout(context),
          ),
        ],
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
            if (b.values.isEmpty) {
              return const Center(
                child: Text(
                  'No profiles yet',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              );
            }

            // Group ALL transactions (paid + unpaid) by person
            final Map<String, List<MoneyTransaction>> byPerson = {};
            for (final t in b.values) {
              byPerson.putIfAbsent(t.personName, () => []).add(t);
            }

            // Sort by outstanding (unpaid) balance descending
            final entries = byPerson.entries.toList()
              ..sort((a, b) {
                final balA = calculateBalance(
                    a.value.where((t) => !t.isPaid).toList());
                final balB = calculateBalance(
                    b.value.where((t) => !t.isPaid).toList());
                return balB.compareTo(balA);
              });

            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                final allTxns = entry.value;
                final unpaidTxns =
                    allTxns.where((t) => !t.isPaid).toList();
                final paidTxns =
                    allTxns.where((t) => t.isPaid).toList();

                final outstandingBalance =
                    calculateBalance(unpaidTxns);
                final totalTransactions = allTxns.length;
                final paidCount = paidTxns.length;

                return Card(
                  color: Colors.black.withOpacity(0.55),
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfileDetailScreen(
                            personName: entry.key,
                          ),
                        ),
                      );
                    },
                    leading: CircleAvatar(
                      backgroundColor: outstandingBalance >= 0
                          ? Colors.green
                          : Colors.red,
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      entry.key,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Row(
                      children: [
                        Text(
                          '$totalTransactions txn${totalTransactions == 1 ? '' : 's'}',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12),
                        ),
                        if (paidCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color:
                                  Colors.greenAccent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '$paidCount paid',
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          unpaidTxns.isEmpty
                              ? 'Settled'
                              : '${outstandingBalance >= 0 ? '+' : '-'}${formatAmount(outstandingBalance.abs())}',
                          style: TextStyle(
                            color: unpaidTxns.isEmpty
                                ? Colors.greenAccent
                                : (outstandingBalance >= 0
                                    ? Colors.green
                                    : Colors.redAccent),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        if (unpaidTxns.isEmpty)
                          const Text(
                            'All paid',
                            style: TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 11),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
