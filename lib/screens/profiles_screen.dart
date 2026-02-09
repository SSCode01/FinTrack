import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/money_transaction.dart';
import '../utils/balance_utils.dart';
import 'profile_detail_screen.dart';

class ProfilesScreen extends StatelessWidget {
  const ProfilesScreen({super.key});

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

            // 🔹 Group transactions by person
            final Map<String, List<MoneyTransaction>> byPerson = {};
            for (final t in b.values) {
              byPerson.putIfAbsent(t.personName, () => []).add(t);
            }

            // 🔹 Sort by highest balance → lowest
            final entries = byPerson.entries.toList()
              ..sort(
                    (a, b) => calculateBalance(b.value)
                    .compareTo(calculateBalance(a.value)),
              );

            return ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                final balance = calculateBalance(entry.value);

                return Card(
                  color: Colors.black.withOpacity(0.55),
                  margin:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                      backgroundColor:
                      balance >= 0 ? Colors.green : Colors.red,
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
                    trailing: Text(
                      '${balance >= 0 ? '+' : '-'}₹${balance.abs()}',
                      style: TextStyle(
                        color: balance >= 0
                            ? Colors.green
                            : Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
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
