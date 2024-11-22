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
    final snapshot = await _firestore.collection('members').get();
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
      final expenseRef = await _firestore.collection('expenses').add({
        "title": _title,
        "amount": _amount,
        "payerId": _selectedPayer,
        "sharedWith": _selectedParticipants,
        "timestamp": FieldValue.serverTimestamp(),
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
    final payerDoc =
        await _firestore.collection('debts').doc(participantId).get();

    if (payerDoc.exists) {
      // Update existing debts
      final currentDebts = Map<String, dynamic>.from(payerDoc['debts']);
      currentDebts[payerId] = (currentDebts[payerId] ?? 0.0) + amount;

      await _firestore.collection('debts').doc(participantId).update({
        "debts": currentDebts,
        "totalDebt": (payerDoc['totalDebt'] ?? 0.0) + amount,
      });
    } else {
      // Create new debt entry
      await _firestore.collection('debts').doc(participantId).set({
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
}
