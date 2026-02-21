import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/money_transaction.dart';
import '../services/transaction_service.dart';
import '../utils/format_utils.dart';
import 'add_transaction_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          cursorColor: const Color(0xFFFFD700),
          decoration: InputDecoration(
            hintText: 'Search people, notes, amounts...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
            border: InputBorder.none,
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white54),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  )
                : null,
          ),
          onChanged: (val) => setState(() => _query = val.toLowerCase().trim()),
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
                child: CircularProgressIndicator(color: Color(0xFFFFD700)),
              );
            }

            final all = snapshot.data ?? [];

            if (_query.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search,
                        color: Colors.white24, size: 72),
                    const SizedBox(height: 16),
                    const Text(
                      'Search across all transactions',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'by name, note or amount',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  ],
                ),
              );
            }

            final results = all.where((t) {
              return t.personName.toLowerCase().contains(_query) ||
                  t.note.toLowerCase().contains(_query) ||
                  t.amount.toString().contains(_query);
            }).toList()
              ..sort((a, b) => b.date.compareTo(a.date));

            if (results.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.search_off,
                        color: Colors.white24, size: 72),
                    const SizedBox(height: 16),
                    Text(
                      'No results for "$_query"',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            // Group into active and past
            final active = results.where((t) => !t.isPaid).toList();
            final past = results.where((t) => t.isPaid).toList();

            return ListView(
              padding: const EdgeInsets.only(bottom: 40),
              children: [
                // RESULT COUNT
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    '${results.length} result${results.length == 1 ? '' : 's'} found',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13),
                  ),
                ),

                if (active.isNotEmpty) ...[
                  _sectionHeader('Active Transactions', active.length),
                  ...active.map((txn) => _txnCard(txn, context)),
                ],

                if (past.isNotEmpty) ...[
                  _sectionHeader('Past Transactions', past.length),
                  ...past.map((txn) => _txnCard(txn, context, isPast: true)),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Row(
        children: [
          Text(title,
              style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$count',
                style: const TextStyle(
                    color: Color(0xFFFFD700), fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _txnCard(MoneyTransaction txn, BuildContext context,
      {bool isPast = false}) {
    return Card(
      color: Colors.black.withOpacity(isPast ? 0.4 : 0.55),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: ListTile(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddTransactionScreen(existingTxn: txn),
            ),
          );
        },
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              backgroundColor: (txn.isCredit ? Colors.green : Colors.red)
                  .withOpacity(isPast ? 0.5 : 1.0),
              child: Icon(
                txn.isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                color: Colors.white,
                size: 18,
              ),
            ),
            if (isPast)
              Positioned(
                right: -3,
                bottom: -3,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: const Icon(Icons.check, size: 9, color: Colors.black),
                ),
              ),
          ],
        ),
        title: _highlightText(txn.personName, _query),
        subtitle: txn.note.isNotEmpty
            ? _highlightText(
                '${txn.note} • ${_formatDate(txn.date)}', _query)
            : Text(_formatDate(txn.date),
                style: const TextStyle(color: Colors.white60, fontSize: 12)),
        trailing: Text(
          '${txn.isCredit ? '+' : '-'}${formatAmount(txn.amount)}',
          style: TextStyle(
            color: (txn.isCredit ? Colors.green : Colors.redAccent)
                .withOpacity(isPast ? 0.6 : 1.0),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // Highlights matching text in gold
  Widget _highlightText(String text, String query) {
    if (query.isEmpty) {
      return Text(text,
          style: const TextStyle(color: Colors.white, fontSize: 13));
    }
    final lowerText = text.toLowerCase();
    final idx = lowerText.indexOf(query);
    if (idx == -1) {
      return Text(text,
          style: const TextStyle(color: Colors.white, fontSize: 13));
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.white, fontSize: 13),
        children: [
          TextSpan(text: text.substring(0, idx)),
          TextSpan(
            text: text.substring(idx, idx + query.length),
            style: const TextStyle(
              color: Color(0xFFFFD700),
              fontWeight: FontWeight.bold,
              backgroundColor: Color(0x33FFD700),
            ),
          ),
          TextSpan(text: text.substring(idx + query.length)),
        ],
      ),
    );
  }
}
