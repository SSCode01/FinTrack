import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/money_transaction.dart';
import '../services/transaction_service.dart';
import '../utils/balance_utils.dart';
import '../utils/format_utils.dart';
import 'add_transaction_screen.dart';

class ProfileDetailScreen extends StatefulWidget {
  final String personName;

  const ProfileDetailScreen({super.key, required this.personName});

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(widget.personName,
            style: const TextStyle(
                color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1B5E20),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: StreamBuilder<List<MoneyTransaction>>(
        stream: TransactionService.transactionsStream(),
        builder: (context, snapshot) {
          final allTxns = (snapshot.data ?? [])
              .where((t) => t.personName == widget.personName && !t.isPaid)
              .toList()
            ..sort((a, b) => a.date.compareTo(b.date));
          if (allTxns.isEmpty) return const SizedBox.shrink();
          
          return FloatingActionButton.extended(
            onPressed: () => _settleUp(allTxns),
            backgroundColor: const Color(0xFF1B5E20),
            icon: const Icon(Icons.handshake, color: Color(0xFFFFD700)),
            label: const Text('Settle Up', style: TextStyle(color: Color(0xFFFFD700))),
          );
        },
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

            final allTxns = (snapshot.data ?? [])
                .where((t) => t.personName == widget.personName)
                .toList()
              ..sort((a, b) => a.date.compareTo(b.date));

            final unpaid = allTxns.where((t) => !t.isPaid).toList();
            final paid = allTxns.where((t) => t.isPaid).toList();
            final outstanding = calculateBalance(unpaid);
            final total = calculateBalance(allTxns);

            return Column(
              children: [
                // STATS HEADER
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _statBlock(
                        label: 'Outstanding',
                        value:
                            '${outstanding >= 0 ? '+' : '-'}${formatAmount(outstanding.abs())}',
                        color: outstanding >= 0
                            ? Colors.green
                            : Colors.redAccent,
                      ),
                      Container(
                          width: 1, height: 40, color: Colors.white24),
                      _statBlock(
                        label: 'Total (all)',
                        value:
                            '${total >= 0 ? '+' : '-'}${formatAmount(total.abs())}',
                        color: Colors.white,
                      ),
                      Container(
                          width: 1, height: 40, color: Colors.white24),
                      _statBlock(
                        label: 'Paid',
                        value: '${paid.length}',
                        color: Colors.greenAccent,
                        suffix: ' txns',
                      ),
                    ],
                  ),
                ),

                // CHAT LEGEND
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.red.shade300,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text('I owe them',
                              style: TextStyle(
                                  color: Colors.white60, fontSize: 12)),
                        ],
                      ),
                      Row(
                        children: [
                          const Text('They owe me',
                              style: TextStyle(
                                  color: Colors.white60, fontSize: 12)),
                          const SizedBox(width: 6),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // CHAT LIST
                Expanded(
                  child: allTxns.isEmpty
                      ? const Center(
                          child: Text('No transactions',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 16)),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
                          itemCount: allTxns.length,
                          itemBuilder: (context, index) {
                            final t = allTxns[index];
                            // isCredit = they owe me → right side (green)
                            // !isCredit = I owe them → left side (red)
                            final isRight = t.isCredit;

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        AddTransactionScreen(existingTxn: t),
                                  ),
                                );
                              },
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 5),
                                child: Row(
                                  mainAxisAlignment: isRight
                                      ? MainAxisAlignment.end
                                      : MainAxisAlignment.start,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.end,
                                  children: [
                                    // LEFT AVATAR (I owe them)
                                    if (!isRight) ...[
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor:
                                            Colors.red.shade700,
                                        child: Text(
                                          widget.personName[0].toUpperCase(),
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],

                                    // BUBBLE
                                    Flexible(
                                      child: Container(
                                        constraints: BoxConstraints(
                                          maxWidth: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.65,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: isRight
                                              ? const Color(0xFF0D3320)
                                              : const Color(0xFF2D0F0F),
                                          borderRadius: BorderRadius.only(
                                            topLeft:
                                                const Radius.circular(16),
                                            topRight:
                                                const Radius.circular(16),
                                            bottomLeft: Radius.circular(
                                                isRight ? 16 : 4),
                                            bottomRight: Radius.circular(
                                                isRight ? 4 : 16),
                                          ),
                                          border: Border.all(
                                            color: isRight
                                                ? Colors.green
                                                    .withOpacity(0.4)
                                                : Colors.red
                                                    .withOpacity(0.4),
                                            width: 1,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.2),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment: isRight
                                              ? CrossAxisAlignment.end
                                              : CrossAxisAlignment.start,
                                          children: [
                                            // AMOUNT
                                            Text(
                                              '${isRight ? '+' : '-'}${formatAmount(t.amount - t.settledAmount)}',
                                              style: TextStyle(
                                                color: isRight
                                                    ? Colors.greenAccent
                                                    : Colors.red.shade300,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                            ),
                                            if (t.settledAmount > 0 && !t.isPaid)
                                              Text(
                                                'Original: ${formatAmount(t.amount)} (Settled: ${formatAmount(t.settledAmount)})',
                                                style: const TextStyle(
                                                    color: Colors.white54,
                                                    fontSize: 10),
                                              ),

                                            // NOTE
                                            if (t.note.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                t.note,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],

                                            const SizedBox(height: 6),

                                            // DATE + PAID BADGE
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (t.isPaid) ...[
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.greenAccent
                                                          .withOpacity(0.2),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6),
                                                      border: Border.all(
                                                          color: Colors
                                                              .greenAccent
                                                              .withOpacity(
                                                                  0.5)),
                                                    ),
                                                    child: const Text(
                                                      'PAID',
                                                      style: TextStyle(
                                                        color:
                                                            Colors.greenAccent,
                                                        fontSize: 9,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        letterSpacing: 1,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                ],
                                                Text(
                                                  _formatDate(t.date),
                                                  style: TextStyle(
                                                    color: Colors.white
                                                        .withOpacity(0.45),
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // RIGHT AVATAR (they owe me)
                                    if (isRight) ...[
                                      const SizedBox(width: 8),
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: Colors.green.shade700,
                                        child: const Icon(Icons.person,
                                            color: Colors.white, size: 16),
                                      ),
                                    ],
                                  ],
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
        Text('$value$suffix',
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 4),
        Text(label,
            style:
                const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Future<void> _settleUp(List<MoneyTransaction> unpaidTxns) async {
    final amountCtrl = TextEditingController();
    bool theyPaidMe = true; 

    final outstanding = calculateBalance(unpaidTxns);
    if (outstanding < 0) theyPaidMe = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setStateSB) {
          return AlertDialog(
            backgroundColor: const Color(0xFF0D1F2D),
            title: const Text('Record Payment', style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: Text(theyPaidMe ? 'They paid me' : 'I paid them', style: const TextStyle(color: Colors.white)),
                  value: theyPaidMe,
                  onChanged: (val) => setStateSB(() => theyPaidMe = val),
                  activeColor: Colors.greenAccent,
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true), 
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
                child: const Text('Settle', style: TextStyle(color: Color(0xFFFFD700))),
              ),
            ],
          );
        });
      },
    );

    if (result != true) return;

    double payment = double.tryParse(amountCtrl.text) ?? 0;
    if (payment <= 0) return;

    final targetTxns = unpaidTxns.where((t) => t.isCredit == theyPaidMe && !t.isPaid).toList();

    for (final txn in targetTxns) {
      if (payment <= 0) break;
      
      double remaining = txn.amount - txn.settledAmount;
      if (payment >= remaining) {
        txn.settledAmount += remaining;
        txn.isPaid = true;
        payment -= remaining;
      } else {
        txn.settledAmount += payment;
        payment = 0;
      }
      await TransactionService.updateTransaction(txn);
    }
  }
}
