import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/money_transaction.dart';
import '../services/transaction_service.dart';
import '../utils/format_utils.dart';
import '../utils/toast.dart';
import 'add_transaction_screen.dart';

/// Call this anywhere to show the edit/delete bottom sheet for a transaction
Future<void> showTransactionActions(
    BuildContext context, MoneyTransaction txn) async {
  HapticFeedback.lightImpact();

  await showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _TransactionActionSheet(txn: txn, parentContext: context),
  );
}

class _TransactionActionSheet extends StatelessWidget {
  final MoneyTransaction txn;
  final BuildContext parentContext;

  const _TransactionActionSheet(
      {required this.txn, required this.parentContext});

  Future<void> _confirmDelete(BuildContext sheetCtx) async {
    Navigator.pop(sheetCtx); // close bottom sheet first
    HapticFeedback.mediumImpact();

    final confirm = await showDialog<bool>(
      context: parentContext,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1F2D),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.delete_forever, color: Colors.redAccent, size: 24),
            SizedBox(width: 10),
            Text('Delete Transaction',
                style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TRANSACTION PREVIEW
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        txn.isCredit ? Colors.green : Colors.red,
                    radius: 18,
                    child: Text(
                      txn.personName[0].toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(txn.personName,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                        if (txn.note.isNotEmpty)
                          Text(txn.note,
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),
                  Text(
                    '${txn.isCredit ? '+' : '-'}${formatAmount(txn.amount)}',
                    style: TextStyle(
                      color:
                          txn.isCredit ? Colors.greenAccent : Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'This action cannot be undone.',
              style: TextStyle(color: Colors.white54, fontSize: 13),
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
            icon: const Icon(Icons.delete, color: Colors.white, size: 16),
            label: const Text('Delete',
                style: TextStyle(color: Colors.white, fontSize: 15)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await TransactionService.deleteTransaction(txn.id);
      if (parentContext.mounted) {
        showToast(
          parentContext,
          message: 'Transaction\nDeleted',
          type: ToastType.error,
          icon: Icons.delete_rounded,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: const Color(0xFFFFD700).withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // HANDLE
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // TRANSACTION PREVIEW HEADER
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      txn.isCredit ? Colors.green : Colors.red,
                  radius: 22,
                  child: Text(
                    txn.personName[0].toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(txn.personName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      if (txn.note.isNotEmpty)
                        Text(txn.note,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${txn.isCredit ? '+' : '-'}${formatAmount(txn.amount)}',
                      style: TextStyle(
                        color: txn.isCredit
                            ? Colors.greenAccent
                            : Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      txn.isPaid ? 'PAID' : 'UNPAID',
                      style: TextStyle(
                        color:
                            txn.isPaid ? Colors.greenAccent : Colors.white38,
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white12, height: 24),

          // ACTION BUTTONS
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              children: [
                // EDIT
                _actionTile(
                  icon: Icons.edit_outlined,
                  iconColor: Colors.blue,
                  label: 'Edit Transaction',
                  subtitle: 'Modify amount, note or status',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                    Navigator.push(
                      parentContext,
                      MaterialPageRoute(
                        builder: (_) =>
                            AddTransactionScreen(existingTxn: txn),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 8),

                // MARK AS PAID / UNPAID
                _actionTile(
                  icon: txn.isPaid
                      ? Icons.undo_rounded
                      : Icons.check_circle_outline,
                  iconColor:
                      txn.isPaid ? Colors.orange : Colors.greenAccent,
                  label: txn.isPaid
                      ? 'Mark as Unpaid'
                      : 'Mark as Paid',
                  subtitle: txn.isPaid
                      ? 'Move back to active transactions'
                      : 'Move to past transactions',
                  onTap: () async {
                    HapticFeedback.mediumImpact();
                    Navigator.pop(context);
                    final updated = MoneyTransaction(
                      id: txn.id,
                      personName: txn.personName,
                      amount: txn.amount,
                      isCredit: txn.isCredit,
                      note: txn.note,
                      date: txn.date,
                      isPaid: !txn.isPaid,
                    );
                    await TransactionService.updateTransaction(updated);
                    if (parentContext.mounted) {
                      showToast(
                        parentContext,
                        message: txn.isPaid
                            ? 'Marked as\nUnpaid'
                            : 'Marked as\nPaid!',
                        type: ToastType.success,
                        icon: txn.isPaid
                            ? Icons.undo_rounded
                            : Icons.check_circle_rounded,
                      );
                    }
                  },
                ),

                const SizedBox(height: 8),

                // DELETE
                _actionTile(
                  icon: Icons.delete_outline,
                  iconColor: Colors.redAccent,
                  label: 'Delete Transaction',
                  subtitle: 'Permanently remove this transaction',
                  onTap: () => _confirmDelete(context),
                  isDestructive: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDestructive
              ? Colors.red.withOpacity(0.08)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDestructive
                ? Colors.red.withOpacity(0.2)
                : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: isDestructive
                              ? Colors.redAccent
                              : Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: isDestructive
                    ? Colors.redAccent.withOpacity(0.5)
                    : Colors.white24,
                size: 20),
          ],
        ),
      ),
    );
  }
}
