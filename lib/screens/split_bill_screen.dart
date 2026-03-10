import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../models/money_transaction.dart';
import '../services/transaction_service.dart';
import '../utils/format_utils.dart';

class SplitBillScreen extends StatefulWidget {
  const SplitBillScreen({super.key});

  @override
  State<SplitBillScreen> createState() => _SplitBillScreenState();
}

class _SplitBillScreenState extends State<SplitBillScreen> {
  final _totalController = TextEditingController();
  final _noteController = TextEditingController();
  final _nameController = TextEditingController();

  List<_SplitPerson> _people = [_SplitPerson(name: 'Me', isMe: true)];
  bool _equalSplit = true;
  bool _paidByMe = true;
  String? _paidByPersonName; // selected payer when _paidByMe = false
  bool _isLoading = false;

  double get _totalAmount =>
      double.tryParse(_totalController.text) ?? 0;

  double get _amountPerPerson =>
      _people.isEmpty ? 0 : _totalAmount / _people.length;

  double get _assignedTotal =>
      _people.fold(0, (sum, p) => sum + (p.customAmount ?? 0));

  double get _remaining => _totalAmount - _assignedTotal;

  void _addPerson() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    if (_people.any((p) => p.name.toLowerCase() == name.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Person already added'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    HapticFeedback.lightImpact();
    setState(() {
      _people.add(_SplitPerson(name: name));
      _nameController.clear();
    });
  }

  void _removePerson(int index) {
    HapticFeedback.mediumImpact();
    setState(() => _people.removeAt(index));
  }

  Future<void> _createTransactions() async {
    if (_totalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Enter a valid total amount'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final others = _people.where((p) => !p.isMe).toList();
    if (others.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Add at least one other person'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    if (!_paidByMe && _paidByPersonName == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Select who paid the bill'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    if (!_equalSplit && _remaining.abs() > 1) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Amounts don\'t add up. Remaining: ${formatAmount(_remaining)}'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    final note = _noteController.text.trim().isNotEmpty
        ? _noteController.text.trim()
        : 'Split bill';

    if (_paidByMe) {
      // Mode 1: I paid — create "they owe me" transactions for each other person
      for (final person in others) {
        final amount = _equalSplit ? _amountPerPerson : (person.customAmount ?? 0);
        if (amount <= 0) continue;
        await TransactionService.addTransaction(MoneyTransaction(
          id: const Uuid().v4(),
          personName: person.name,
          amount: double.parse(amount.toStringAsFixed(2)),
          isCredit: true, // they owe me
          note: note,
          date: DateTime.now(),
          isPaid: false,
        ));
      }
    } else {
      // Mode 2: Someone else paid — create one "I owe them" transaction for my share
      final meShare = _equalSplit
          ? _amountPerPerson
          : (_people.firstWhere((p) => p.isMe).customAmount ?? _amountPerPerson);
      await TransactionService.addTransaction(MoneyTransaction(
        id: const Uuid().v4(),
        personName: _paidByPersonName!,
        amount: double.parse(meShare.toStringAsFixed(2)),
        isCredit: false, // I owe them
        note: note,
        date: DateTime.now(),
        isPaid: false,
      ));
    }

    HapticFeedback.heavyImpact();

    if (mounted) {
      Navigator.pop(context);
      final msg = _paidByMe
          ? '✓ Split across ${others.length} people created!'
          : '✓ Added: you owe $_paidByPersonName ${formatAmount(_equalSplit ? _amountPerPerson : (_people.firstWhere((p) => p.isMe).customAmount ?? _amountPerPerson))}';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF1B5E20),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        duration: const Duration(seconds: 3),
      ));
    }
  }

  Color _avatarColor(String name) {
    final colors = [
      Colors.purple,
      Colors.blue,
      Colors.teal,
      Colors.orange,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
      Colors.amber,
    ];
    return colors[name.codeUnitAt(0) % colors.length];
  }

  @override
  void dispose() {
    _totalController.dispose();
    _noteController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Split Bill',
          style: TextStyle(
              color: Color(0xFFFFD700), fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1B5E20),
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
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // BILL DETAILS CARD
            _sectionCard(
              title: 'Bill Details',
              icon: Icons.receipt_long,
              child: Column(
                children: [
                  _buildField(
                    controller: _totalController,
                    label: 'Total Bill Amount',
                    icon: Icons.currency_rupee,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    controller: _noteController,
                    label: 'What was this for? (e.g. Dinner)',
                    icon: Icons.notes,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // SPLIT TYPE
            _sectionCard(
              title: 'Split Type',
              icon: Icons.call_split,
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _equalSplit = true);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _equalSplit
                              ? const Color(0xFF2E7D32)
                              : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _equalSplit
                                ? const Color(0xFFFFD700)
                                : Colors.white24,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.people,
                                color: _equalSplit
                                    ? const Color(0xFFFFD700)
                                    : Colors.white54),
                            const SizedBox(height: 4),
                            Text(
                              'Equal Split',
                              style: TextStyle(
                                color: _equalSplit
                                    ? const Color(0xFFFFD700)
                                    : Colors.white54,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _equalSplit = false);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_equalSplit
                              ? const Color(0xFF2E7D32)
                              : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: !_equalSplit
                                ? const Color(0xFFFFD700)
                                : Colors.white24,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.tune,
                                color: !_equalSplit
                                    ? const Color(0xFFFFD700)
                                    : Colors.white54),
                            const SizedBox(height: 4),
                            Text(
                              'Custom Split',
                              style: TextStyle(
                                color: !_equalSplit
                                    ? const Color(0xFFFFD700)
                                    : Colors.white54,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // PAID BY
            _sectionCard(
              title: 'Paid By',
              icon: Icons.payments_outlined,
              child: Column(
                children: [
                  // Me vs Someone else toggle
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _paidByMe = true;
                              _paidByPersonName = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _paidByMe
                                  ? const Color(0xFF2E7D32)
                                  : Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _paidByMe
                                    ? const Color(0xFFFFD700)
                                    : Colors.white24,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.person,
                                    color: _paidByMe
                                        ? const Color(0xFFFFD700)
                                        : Colors.white54),
                                const SizedBox(height: 4),
                                Text('Me',
                                    style: TextStyle(
                                        color: _paidByMe
                                            ? const Color(0xFFFFD700)
                                            : Colors.white54,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _paidByMe = false);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !_paidByMe
                                  ? const Color(0xFF2E7D32)
                                  : Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: !_paidByMe
                                    ? const Color(0xFFFFD700)
                                    : Colors.white24,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.group,
                                    color: !_paidByMe
                                        ? const Color(0xFFFFD700)
                                        : Colors.white54),
                                const SizedBox(height: 4),
                                Text('Someone else',
                                    style: TextStyle(
                                        color: !_paidByMe
                                            ? const Color(0xFFFFD700)
                                            : Colors.white54,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Person picker — shown only when "someone else" is selected
                  if (!_paidByMe) ...[
                    const SizedBox(height: 12),
                    if (_people.where((p) => !p.isMe).isEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.orange.withOpacity(0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange, size: 16),
                            SizedBox(width: 8),
                            Text('Add people below first',
                                style: TextStyle(color: Colors.orange, fontSize: 13)),
                          ],
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _people.where((p) => !p.isMe).map((person) {
                          final selected = _paidByPersonName == person.name;
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _paidByPersonName = person.name);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0xFFFFD700).withOpacity(0.15)
                                    : Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: selected
                                      ? const Color(0xFFFFD700)
                                      : Colors.white24,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (selected)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 6),
                                      child: Icon(Icons.check_circle,
                                          color: Color(0xFFFFD700), size: 14),
                                    ),
                                  Text(person.name,
                                      style: TextStyle(
                                          color: selected
                                              ? const Color(0xFFFFD700)
                                              : Colors.white70,
                                          fontWeight: selected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          fontSize: 13)),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // PEOPLE CARD
            _sectionCard(
              title: 'People',
              icon: Icons.group,
              child: Column(
                children: [
                  // ADD PERSON ROW
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          style: const TextStyle(color: Colors.white),
                          onSubmitted: (_) => _addPerson(),
                          decoration: InputDecoration(
                            hintText: 'Enter name',
                            hintStyle:
                                const TextStyle(color: Colors.white38),
                            prefixIcon: const Icon(Icons.person_add,
                                color: Colors.white54),
                            filled: true,
                            fillColor: const Color(0xFF081520),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _addPerson,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFFFFD700)
                                    .withOpacity(0.5)),
                          ),
                          child: const Icon(Icons.add,
                              color: Color(0xFFFFD700), size: 22),
                        ),
                      ),
                    ],
                  ),

                  if (_people.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    // EQUAL SPLIT SUMMARY
                    if (_equalSplit && _totalAmount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Each person pays',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                            Text(
                              formatAmount(_amountPerPerson),
                              style: const TextStyle(
                                color: Color(0xFFFFD700),
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // CUSTOM SPLIT REMAINING
                    if (!_equalSplit && _totalAmount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: _remaining.abs() < 1
                              ? Colors.green.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _remaining.abs() < 1
                                ? Colors.greenAccent.withOpacity(0.3)
                                : Colors.orange.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _remaining.abs() < 1
                                  ? '✓ Fully allocated'
                                  : 'Remaining to assign',
                              style: TextStyle(
                                color: _remaining.abs() < 1
                                    ? Colors.greenAccent
                                    : Colors.orange,
                                fontSize: 13,
                              ),
                            ),
                            if (_remaining.abs() >= 1)
                              Text(
                                formatAmount(_remaining),
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                          ],
                        ),
                      ),

                    // PERSON LIST
                    ...List.generate(_people.length, (i) {
                      final person = _people[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: person.isMe
                              ? const Color(0xFFFFD700).withOpacity(0.07)
                              : Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: person.isMe
                                ? const Color(0xFFFFD700).withOpacity(0.35)
                                : Colors.white.withOpacity(0.08),
                          ),
                        ),
                        child: Row(
                          children: [
                            // AVATAR
                            CircleAvatar(
                              backgroundColor: person.isMe
                                  ? const Color(0xFFFFD700)
                                  : _avatarColor(person.name),
                              radius: 18,
                              child: Text(
                                person.name[0].toUpperCase(),
                                style: TextStyle(
                                    color: person.isMe ? Colors.black : Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // NAME + ME BADGE
                            Expanded(
                              child: Row(
                                children: [
                                  Text(
                                    person.name,
                                    style: TextStyle(
                                        color: person.isMe
                                            ? const Color(0xFFFFD700)
                                            : Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14),
                                  ),
                                  if (person.isMe) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFD700).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text('you',
                                          style: TextStyle(
                                              color: Color(0xFFFFD700),
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // AMOUNT
                            if (_equalSplit)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _totalAmount > 0 ? formatAmount(_amountPerPerson) : '—',
                                    style: const TextStyle(
                                        color: Color(0xFFFFD700),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14),
                                  ),
                                  if (person.isMe)
                                    const Text('your share',
                                        style: TextStyle(color: Colors.white38, fontSize: 10)),
                                ],
                              )
                            else
                              SizedBox(
                                width: 90,
                                child: TextField(
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(color: Colors.white, fontSize: 14),
                                  textAlign: TextAlign.center,
                                  decoration: InputDecoration(
                                    hintText: '0',
                                    hintStyle: const TextStyle(color: Colors.white38),
                                    filled: true,
                                    fillColor: const Color(0xFF081520),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  onChanged: (val) {
                                    setState(() => _people[i].customAmount = double.tryParse(val));
                                  },
                                ),
                              ),

                            const SizedBox(width: 8),

                            // REMOVE
                            GestureDetector(
                              onTap: () => _removePerson(i),
                              child: Icon(
                                person.isMe ? Icons.person_remove_outlined : Icons.remove_circle,
                                color: person.isMe ? Colors.white38 : Colors.redAccent,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // SUMMARY + CREATE BUTTON
            if (_people.isNotEmpty && _totalAmount > 0)
              Builder(builder: (_) {
                final others = _people.where((p) => !p.isMe).toList();
                return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFFFFD700).withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Bill',
                            style: TextStyle(color: Colors.white70, fontSize: 13)),
                        Text(formatAmount(_totalAmount),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Splitting between',
                            style: TextStyle(color: Colors.white70, fontSize: 13)),
                        Text('${_people.length} people (incl. you)',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Your share',
                            style: TextStyle(color: Colors.white70, fontSize: 13)),
                        Text(
                          formatAmount(_equalSplit
                              ? _amountPerPerson
                              : (_people.firstWhere((p) => p.isMe,
                                      orElse: () => _SplitPerson(name: 'Me', isMe: true))
                                  .customAmount ?? 0)),
                          style: const TextStyle(
                              color: Color(0xFFFFD700),
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Paid by',
                            style: TextStyle(color: Colors.white70, fontSize: 13)),
                        Text(
                          _paidByMe ? 'You' : (_paidByPersonName ?? 'Not selected'),
                          style: TextStyle(
                              color: _paidByMe || _paidByPersonName != null
                                  ? Colors.white
                                  : Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _createTransactions,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B5E20),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: _isLoading
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(
                                    color: Color(0xFFFFD700), strokeWidth: 2))
                            : const Icon(Icons.call_split, color: Color(0xFFFFD700)),
                        label: Text(
                          _isLoading
                              ? 'Creating...'
                              : _paidByMe
                                  ? 'Create ${others.length} Transaction${others.length != 1 ? 's' : ''}'
                                  : 'Add: I owe ${_paidByPersonName ?? '...'}',
                          style: const TextStyle(
                              color: Color(0xFFFFD700),
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              );
              }),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFFFD700), size: 18),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      onChanged: onChanged,
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

class _SplitPerson {
  final String name;
  final bool isMe;
  double? customAmount;

  _SplitPerson({required this.name, this.isMe = false, this.customAmount});
}
