import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../models/money_transaction.dart';
import '../services/transaction_service.dart';
import '../utils/categories.dart';
import '../utils/toast.dart';

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
  String _selectedCategory = 'Other';

  @override
  void initState() {
    super.initState();
    if (widget.existingTxn != null) {
      _nameController.text = widget.existingTxn!.personName;
      _amountController.text = widget.existingTxn!.amount.toString();
      _noteController.text = widget.existingTxn!.note;
      isCredit = widget.existingTxn!.isCredit;
      isPaid = widget.existingTxn!.isPaid;
      _selectedCategory = widget.existingTxn!.category;
    }
  }

  Future<void> _saveTransaction() async {
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text);
    if (name.isEmpty || amount == null) {
      HapticFeedback.heavyImpact();
      showToast(context,
          message: 'Please fill in\nname and amount',
          type: ToastType.error,
          icon: Icons.error_outline_rounded);
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
      category: _selectedCategory,
    );

    if (widget.existingTxn != null) {
      await TransactionService.updateTransaction(txn);
    } else {
      await TransactionService.addTransaction(txn);
    }

    HapticFeedback.lightImpact();

    if (mounted) {
      Navigator.pop(context);
      showToast(
        context,
        message: widget.existingTxn != null
            ? 'Transaction\nUpdated!'
            : 'Transaction\nSaved!',
        type: ToastType.success,
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
        iconTheme: const IconThemeData(color: Colors.white),
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Card(
              color: Colors.white.withOpacity(0.07),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
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

                    // CATEGORY PICKER
                    const Text(
                      'Category',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: kCategories.length,
                        itemBuilder: (context, index) {
                          final cat = kCategories[index];
                          final isSelected =
                              _selectedCategory == cat.name;
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(
                                  () => _selectedCategory = cat.name);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 10),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? cat.color.withOpacity(0.25)
                                    : Colors.white.withOpacity(0.07),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? cat.color
                                      : Colors.white24,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(cat.icon,
                                      color: isSelected
                                          ? cat.color
                                          : Colors.white54,
                                      size: 22),
                                  const SizedBox(height: 4),
                                  Text(
                                    cat.name.split(' ').first,
                                    style: TextStyle(
                                      color: isSelected
                                          ? cat.color
                                          : Colors.white54,
                                      fontSize: 10,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

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
                          color:
                              isPaid ? Colors.greenAccent : Colors.white54,
                        ),
                        title: Text(
                          isPaid ? 'Paid' : 'Not Paid',
                          style: TextStyle(
                            color: isPaid
                                ? Colors.greenAccent
                                : Colors.white70,
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
                          backgroundColor: const Color(0xFF1B5E20),
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
        fillColor: const Color(0xFF081520),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
