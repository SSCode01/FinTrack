import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/money_transaction.dart';
import '../services/transaction_service.dart';
import '../utils/balance_utils.dart';
import '../utils/format_utils.dart';
import 'profile_detail_screen.dart';
import '../widgets/animated_list_item.dart';
import 'settings_screen.dart';

class ProfilesScreen extends StatelessWidget {
  const ProfilesScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    HapticFeedback.mediumImpact();

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1F2D),
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.white.withOpacity(0.08),
            height: 1,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
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

                int getGroup(double bal) {
                  if (bal > 0) return 0; // Owe me
                  if (bal < 0) return 1; // I owe
                  return 2;              // Settled
                }

                final gA = getGroup(balA);
                final gB = getGroup(balB);

                if (gA != gB) {
                  return gA.compareTo(gB);
                }

                if (gA == 0) {
                  return balB.compareTo(balA); // Sort descending (most owed to me first)
                } else if (gA == 1) {
                  return balA.compareTo(balB); // Sort ascending (most owed by me first)
                } else {
                  return a.key.toLowerCase().compareTo(b.key.toLowerCase()); // Alphabetical for settled
                }
              });

            return ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                final txns = entry.value;
                final unpaid = txns.where((t) => !t.isPaid).toList();
                final paidCount = txns.where((t) => t.isPaid).length;
                final outstanding = calculateBalance(unpaid);
                final initials = entry.key.trim().isNotEmpty
                    ? entry.key.trim()[0].toUpperCase()
                    : '?';

                return Card(
                  color: Colors.white.withOpacity(0.07),
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
                    leading: Hero(
                      tag: 'avatar_${entry.key}',
                      child: CircleAvatar(
                        backgroundColor: outstanding >= 0
                            ? Colors.green.withOpacity(0.2)
                            : Colors.red.withOpacity(0.2),
                        child: Text(
                          initials,
                          style: TextStyle(
                            color: outstanding >= 0
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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
