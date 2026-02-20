import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/money_transaction.dart';
import '../services/transaction_service.dart';
import '../utils/balance_utils.dart';
import '../utils/format_utils.dart';
import 'profile_detail_screen.dart';

class ProfilesScreen extends StatelessWidget {
  const ProfilesScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    HapticFeedback.mediumImpact();

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B3A1F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.logout, color: Colors.redAccent, size: 24),
            SizedBox(width: 10),
            Text('Sign Out',
                style: TextStyle(color: Color(0xFFFFD700), fontSize: 20)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to sign out?',
              style: TextStyle(color: Colors.white, fontSize: 15),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your data is safely stored in the cloud. You can sign back in anytime.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(ctx, false);
            },
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white54, fontSize: 15)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.heavyImpact();
              Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.logout, color: Colors.white, size: 16),
            label: const Text('Sign Out',
                style: TextStyle(color: Colors.white, fontSize: 15)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have been signed out successfully.'),
            backgroundColor: Color(0xFF2E7D32),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Profiles',
            style: TextStyle(
                color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
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
        child: StreamBuilder<List<MoneyTransaction>>(
          stream: TransactionService.transactionsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFFFD700)),
              );
            }

            final allTxns = snapshot.data ?? [];

            if (allTxns.isEmpty) {
              return const Center(
                child: Text('No profiles yet',
                    style: TextStyle(color: Colors.white, fontSize: 18)),
              );
            }

            // Group by person
            final Map<String, List<MoneyTransaction>> byPerson = {};
            for (final t in allTxns) {
              byPerson.putIfAbsent(t.personName, () => []).add(t);
            }

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
                final txns = entry.value;
                final unpaid = txns.where((t) => !t.isPaid).toList();
                final paidCount = txns.where((t) => t.isPaid).length;
                final outstanding = calculateBalance(unpaid);

                return Card(
                  color: Colors.black.withOpacity(0.55),
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ProfileDetailScreen(personName: entry.key),
                      ),
                    ),
                    leading: CircleAvatar(
                      backgroundColor:
                          outstanding >= 0 ? Colors.green : Colors.red,
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(entry.key,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16)),
                    subtitle: Row(
                      children: [
                        Text('${txns.length} txns',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12)),
                        if (paidCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.greenAccent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('$paidCount paid',
                                style: const TextStyle(
                                    color: Colors.greenAccent, fontSize: 11)),
                          ),
                        ],
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          unpaid.isEmpty
                              ? 'Settled'
                              : '${outstanding >= 0 ? '+' : '-'}${formatAmount(outstanding.abs())}',
                          style: TextStyle(
                            color: unpaid.isEmpty
                                ? Colors.greenAccent
                                : (outstanding >= 0
                                    ? Colors.green
                                    : Colors.redAccent),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        if (unpaid.isEmpty)
                          const Text('All paid',
                              style: TextStyle(
                                  color: Colors.greenAccent, fontSize: 11)),
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
