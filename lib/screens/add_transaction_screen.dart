import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../models/money_transaction.dart';
import '../services/transaction_service.dart';

class AddTransactionScreen extends StatefulWidget {
  final MoneyTransaction? existingTxn;

  const AddTransactionScreen({super.key, this.existingTxn});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  bool isCredit = true;
  bool isPaid = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingTxn != null) {
      _nameController.text = widget.existingTxn!.personName;
      _amountController.text = widget.existingTxn!.amount.toString();
      _noteController.text = widget.existingTxn!.note;
      isCredit = widget.existingTxn!.isCredit;
      isPaid = widget.existingTxn!.isPaid;
    }
  }

  Future<void> _saveTransaction() async {
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text);
    if (name.isEmpty || amount == null) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in name and amount'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    final txn = MoneyTransaction(
      id: widget.existingTxn?.id ?? const Uuid().v4(),
      personName: name,
      amount: amount,
      isCredit: isCredit,
      note: _noteController.text.trim(),
      date: DateTime.now(),
      isPaid: isPaid,
    );

    if (widget.existingTxn != null) {
      await TransactionService.updateTransaction(txn);
    } else {
      await TransactionService.addTransaction(txn);
    }

    HapticFeedback.lightImpact();

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.existingTxn != null
              ? '✓ Transaction updated!'
              : '✓ Transaction saved!'),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingTxn != null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Transaction' : 'Add Transaction',
          style: const TextStyle(
              color: Color(0xFFFFD700), fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2E7D32).withOpacity(0.85),
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Card(
              color: Colors.black.withOpacity(0.55),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildField(
                        controller: _nameController,
                        label: 'Person Name',
                        icon: Icons.person),
                    const SizedBox(height: 14),
                    _buildField(
                        controller: _amountController,
                        label: 'Amount',
                        icon: Icons.currency_rupee,
                        keyboardType: TextInputType.number),
                    const SizedBox(height: 14),
                    _buildField(
                        controller: _noteController,
                        label: 'Note',
                        icon: Icons.notes),
                    const SizedBox(height: 20),

                    // WHO OWES WHOM
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: SwitchListTile(
                        title: Text(
                          isCredit ? 'They owe me' : 'I owe them',
                          style: const TextStyle(color: Colors.white),
                        ),
                        value: isCredit,
                        activeColor: const Color(0xFFFFD700),
                        onChanged: (val) {
                          HapticFeedback.selectionClick();
                          setState(() => isCredit = val);
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    // PAID / NOT PAID
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: SwitchListTile(
                        secondary: Icon(
                          isPaid
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: isPaid ? Colors.greenAccent : Colors.white54,
                        ),
                        title: Text(
                          isPaid ? 'Paid' : 'Not Paid',
                          style: TextStyle(
                            color: isPaid ? Colors.greenAccent : Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          isPaid
                              ? 'Moved to Past Transactions'
                              : 'Still active',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 12),
                        ),
                        value: isPaid,
                        activeColor: Colors.greenAccent,
                        onChanged: (val) {
                          HapticFeedback.selectionClick();
                          setState(() => isPaid = val);
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // SAVE BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveTransaction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: Color(0xFFFFD700),
                                    strokeWidth: 2),
                              )
                            : Text(
                                isEdit
                                    ? 'Update Transaction'
                                    : 'Save Transaction',
                                style: const TextStyle(
                                  color: Color(0xFFFFD700),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: Colors.black.withOpacity(0.35),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
