import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddExpenseScreen extends StatefulWidget {
  @override
  _AddExpenseScreenState createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  String _title = '';
  double _amount = 0.0;
  String? _selectedPayer;
  List<String> _selectedParticipants = [];
  List<Map<String, dynamic>> _members = [];

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    final snapshot = await _firestore
        .collection('members')
        .where('userId', isEqualTo: userId)
        .get();
    setState(() {
      _members = snapshot.docs.map((doc) {
        return {
          "id": doc.id,
          "name": doc['name'],
        };
      }).toList();
    });
  }

  Future<void> _addExpense() async {
    if (_formKey.currentState!.validate() &&
        _selectedPayer != null &&
        _selectedParticipants.isNotEmpty) {
      final equalShare = _amount / _selectedParticipants.length;

      // Add expense to 'expenses' collection
      User? user = FirebaseAuth.instance.currentUser;
      final expenseRef = await _firestore.collection('expenses').add({
        "userId": user?.uid,
        "title": _title,
        "amount": _amount,
        "payerId": _selectedPayer,
        "sharedWith": _selectedParticipants,
        "timestamp": FieldValue.serverTimestamp(),
      });

      // Increase the initialPay for the payer in the 'individualExpense' collection
      final individualExpenseDoc =
          _firestore.collection('individualExpense').doc(_selectedPayer);

      // Fetch the current expense data for the payer
      final individualExpenseData =
          (await individualExpenseDoc.get()).data() ?? {};
      double initialPay =
          (individualExpenseData['initialPay'] as num?)?.toDouble() ?? 0.0;
      double debtPay =
          (individualExpenseData['debtPay'] as num?)?.toDouble() ?? 0.0;

      // Increase the initial payment by the total amount of the expense
      initialPay += _amount;

      String? userId = FirebaseAuth.instance.currentUser?.uid;
      // Update the 'individualExpense' document for the payer
      print(userId);
      await individualExpenseDoc.set({
        'userId': userId,
        'initialPay': initialPay,
        'debtPay': debtPay, // Debt pay remains unchanged
      });

      // Update debts for each participant
      for (final participantId in _selectedParticipants) {
        if (participantId != _selectedPayer) {
          await _updateDebts(_selectedPayer!, participantId, equalShare);
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Expense added successfully!')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _updateDebts(
      String payerId, String participantId, double amount) async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;

    final payerDoc =
        await _firestore.collection('debts').doc(participantId).get();

    if (payerDoc.exists) {
      // Update existing debts
      final currentDebts = Map<String, dynamic>.from(payerDoc['debts']);
      currentDebts[payerId] = (currentDebts[payerId] ?? 0.0) + amount;

      await _firestore.collection('debts').doc(participantId).update({
        "userId": userId,
        "debts": currentDebts,
        "totalDebt": (payerDoc['totalDebt'] ?? 0.0) + amount,
      });
    } else {
      // Create new debt entry
      await _firestore.collection('debts').doc(participantId).set({
        "userId": userId,
        "debts": {payerId: amount},
        "totalDebt": amount,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Expense')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Title'),
                onChanged: (value) => _title = value,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a title' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                onChanged: (value) => _amount = double.tryParse(value) ?? 0.0,
                validator: (value) => (double.tryParse(value ?? '') ?? 0.0) <= 0
                    ? 'Enter a valid amount'
                    : null,
              ),
              DropdownButtonFormField<Object>(
                value: _selectedPayer,
                decoration: InputDecoration(labelText: 'Who Paid?'),
                items: _members
                    .map((member) => DropdownMenuItem(
                          value: member['id'],
                          child: Text(member['name']),
                        ))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedPayer = value.toString()),
                validator: (value) => value == null ? 'Select who paid' : null,
              ),
              SizedBox(height: 20),
              Text('Participants', style: TextStyle(fontSize: 16)),
              ElevatedButton(
                onPressed: _toggleSelectAll,
                child: Text(_selectedParticipants.length == _members.length
                    ? 'Deselect All'
                    : 'Select All'),
              ),
              ..._members.map((member) {
                return CheckboxListTile(
                  title: Text(member['name']),
                  value: _selectedParticipants.contains(member['id']),
                  onChanged: (bool? checked) {
                    setState(() {
                      if (checked == true) {
                        _selectedParticipants.add(member['id']);
                      } else {
                        _selectedParticipants.remove(member['id']);
                      }
                    });
                  },
                );
              }).toList(),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addExpense,
                child: Text('Add Expense'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Function to toggle the "Select All" functionality
  void _toggleSelectAll() {
    setState(() {
      if (_selectedParticipants.length == _members.length) {
        // Deselect all if all are selected
        _selectedParticipants.clear();
      } else {
        // Select all if not all are selected
        _selectedParticipants =
            _members.map((member) => member['id'] as String).toList();
      }
    });
  }
}
