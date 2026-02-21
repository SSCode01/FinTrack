import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/money_transaction.dart';
import '../services/transaction_service.dart';
import '../utils/format_utils.dart';
import 'transaction_action_sheet.dart';
import '../widgets/animated_list_item.dart';

class PastTransactionsScreen extends StatefulWidget {
  const PastTransactionsScreen({super.key});

  @override
  State<PastTransactionsScreen> createState() =>
      _PastTransactionsScreenState();
}

class _PastTransactionsScreenState extends State<PastTransactionsScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Past Transactions',
          style: TextStyle(
              color: Color(0xFFFFD700), fontWeight: FontWeight.bold),
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              cursorColor: Color(0xFFFFD700),
              decoration: InputDecoration(
                hintText: 'Search past transactions...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon:
                    const Icon(Icons.search, color: Colors.white38, size: 20),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (val) =>
                  setState(() => _search = val.toLowerCase().trim()),
            ),
          ),
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

            var paid = (snapshot.data ?? [])
                .where((t) => t.isPaid)
                .toList()
              ..sort((a, b) => b.date.compareTo(a.date));

            if (_search.isNotEmpty) {
              paid = paid
                  .where((t) =>
                      t.personName.toLowerCase().contains(_search) ||
                      t.note.toLowerCase().contains(_search))
                  .toList();
            }

            if (paid.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.history,
                        color: Colors.white24, size: 72),
                    const SizedBox(height: 16),
                    Text(
                      _search.isNotEmpty
                          ? 'No results for "$_search"'
                          : 'No past transactions yet',
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 100, top: 8),
              itemCount: paid.length,
              itemBuilder: (context, index) {
                final txn = paid[index];
                return AnimatedListItem(
                  index: index,
                  child: GestureDetector(
                    onLongPress: () => showTransactionActions(context, txn),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter:
                            ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.12)),
                          ),
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
                                        shape: BoxShape.circle),
                                    padding: const EdgeInsets.all(2),
                                    child: const Icon(Icons.check,
                                        size: 10, color: Colors.black),
                                  ),
                                ),
                              ],
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(txn.personName,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600)),
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
                                  child: const Text('PAID',
                                      style: TextStyle(
                                          color: Colors.greenAccent,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1)),
                                ),
                              ],
                            ),
                            subtitle: Text(
                              '${txn.note.isNotEmpty ? txn.note : 'No note'} • ${txn.date.day}/${txn.date.month}/${txn.date.year}',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12),
                            ),
                            trailing: Text(
                              '${txn.isCredit ? '+' : '-'}${formatAmount(txn.amount)}',
                              style: TextStyle(
                                color: txn.isCredit
                                    ? Colors.green.withOpacity(0.8)
                                    : Colors.redAccent.withOpacity(0.8),
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
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
    );
  }
}
