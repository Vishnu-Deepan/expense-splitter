import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettleDebtScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch debts from Firestore
  Future<List<Map<String, dynamic>>> _fetchDebts() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    final snapshot = await _firestore
        .collection('debts')
        .where("userId", isEqualTo: userId)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        "memberId": doc.id,
        "debts": (data['debts'] as Map<String, dynamic>) ?? {},
        "totalDebt": (data['totalDebt'] as num?)?.toDouble() ?? 0.0,
      };
    }).toList();
  }

  // Fetch member name by ID
  Future<String> _getMemberName(String memberId) async {
    final doc = await _firestore.collection('members').doc(memberId).get();
    return doc.data()?['name'] ?? 'Unknown';
  }

  // Show payment dialog
  Future<void> _showPaymentDialog(
      BuildContext context,
      String owedToName,
      String payerName,
      double currentDebt,
      String debtorId,
      String payToId) async {
    TextEditingController amountController = TextEditingController();

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$owedToName Paying To - $payerName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Pending Amount: ₹${currentDebt.toStringAsFixed(2)}'),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Enter Amount'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                double amount = double.tryParse(amountController.text) ?? 0.0;
                if (amount > 0.0 && amount <= currentDebt) {
                  _updateDebt(debtorId, payToId, amount);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid amount entered')),
                  );
                }
              },
              child: const Text('Pay'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateDebt(
      String debtorId, String payToId, double amount) async {
    try {
      final debtorDoc =
          await _firestore.collection('debts').doc(debtorId).get();
      if (!debtorDoc.exists) {
        print('Error: Debtor document not found.');
        return;
      }

      // Get the debts map
      Map<String, dynamic> debts =
          (debtorDoc.data()?['debts'] ?? {}) as Map<String, dynamic>;

      // Subtract the amount from the specific debt
      if (debts.containsKey(payToId)) {
        double currentDebt = (debts[payToId] as num?)?.toDouble() ?? 0.0;
        double newDebt = currentDebt - amount;
        if (newDebt < 0) newDebt = 0; // Ensure debt does not go negative
        debts[payToId] = newDebt;
      } else {
        print('Error: No debt found for $payToId');
        return;
      }

      // Recalculate total debt
      double updatedTotalDebt = debts.values
          .map((debt) => (debt as num?)?.toDouble() ?? 0.0)
          .reduce((a, b) => a + b);

      // Update the debts document in Firestore
      await _firestore.collection('debts').doc(debtorId).update({
        'debts': debts,
        'totalDebt': updatedTotalDebt,
      });

      // Add settlement record
      final settlementDoc = _firestore.collection('settlements').doc(debtorId);
      final settlementData = (await settlementDoc.get()).data() ?? {};
      double currentSettlement =
          (settlementData[payToId] as num?)?.toDouble() ?? 0.0;

      // Update settlement amount
      settlementData[payToId] = currentSettlement + amount;

      // Update or create the settlement document
      await settlementDoc.set(settlementData);

      print('Debt and settlements updated successfully.');
    } catch (e) {
      print('Error updating debt and settlement: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settle Debts'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchDebts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print("Error fetching debts: ${snapshot.error}");
            return const Center(child: Text('Error fetching debts.'));
          }

          final debts = snapshot.data ?? [];

          if (debts.isEmpty) {
            return const Center(child: Text('No debts to display.'));
          }

          return ListView.builder(
            itemCount: debts.length,
            itemBuilder: (context, index) {
              final memberDebt = debts[index];

              return FutureBuilder<String>(
                future: _getMemberName(memberDebt['memberId']),
                builder: (context, memberSnapshot) {
                  if (memberSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const ListTile(title: Text('Loading...'));
                  }

                  if (memberSnapshot.hasError) {
                    print(
                        "Error fetching member name: ${memberSnapshot.error}");
                    return const ListTile(title: Text('Error loading name'));
                  }

                  final memberName = memberSnapshot.data ?? 'Unknown';
                  double totalDebt = memberDebt['totalDebt'] ?? 0.0;

                  return Card(
                    margin: const EdgeInsets.all(8.0),
                    child: ExpansionTile(
                      title:
                          Text('$memberName: ₹${totalDebt.toStringAsFixed(2)}'),
                      children: [
                        ...memberDebt['debts'].entries.map((entry) {
                          return FutureBuilder<String>(
                            future: _getMemberName(entry.key),
                            builder: (context, owedToSnapshot) {
                              if (owedToSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const ListTile(
                                    title: Text('Loading...'));
                              }

                              if (owedToSnapshot.hasError) {
                                print(
                                    "Error fetching owed-to name: ${owedToSnapshot.error}");
                                return const ListTile(
                                    title: Text('Error loading name'));
                              }

                              final owedToName =
                                  owedToSnapshot.data ?? 'Unknown';
                              double debtAmount =
                                  (entry.value as num?)?.toDouble() ?? 0.0;

                              return ListTile(
                                title: Text(
                                    'Pending for $owedToName : ₹${debtAmount.toStringAsFixed(2)}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.payment),
                                  onPressed: () {
                                    _showPaymentDialog(
                                        context,
                                        memberName,
                                        owedToName,
                                        debtAmount,
                                        memberDebt['memberId'],
                                        entry.key);
                                  },
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
