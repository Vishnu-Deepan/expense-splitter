import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseAnalysisScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch the total amount spent overall from the expenses collection
  Future<double> _fetchTotalSpentOverall() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;

    final snapshot = await _firestore
        .collection('expenses')
        .where("userId", isEqualTo: userId)
        .get();
    double totalSpent = 0.0;

    for (var doc in snapshot.docs) {
      totalSpent += (doc.data()['amount'] as num).toDouble();
    }

    return totalSpent;
  }

  // Fetch the total amount spent by each individual from the expenses collection
  Future<Map<String, double>> _fetchTotalSpentByIndividual() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;

    final snapshot = await _firestore
        .collection('expenses')
        .where("userId", isEqualTo: userId)
        .get();
    Map<String, double> totalSpent = {};

    for (var doc in snapshot.docs) {
      final payerId = doc.data()['payerId'] as String;
      final amount = (doc.data()['amount'] as num).toDouble();

      totalSpent[payerId] = (totalSpent[payerId] ?? 0.0) + amount;
    }

    return totalSpent;
  }

  // Fetch the member name from the members collection
  Future<String> _getMemberName(String memberId) async {
    final doc = await _firestore.collection('members').doc(memberId).get();
    return doc.data()?['name'] ?? 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Analysis'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: Future.wait([
          _fetchTotalSpentOverall(),
          _fetchTotalSpentByIndividual(),
        ]).then((results) {
          return {
            'totalSpentOverall': results[0],
            'totalSpentByIndividual': results[1],
          };
        }),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error fetching data: ${snapshot.error}'),
            );
          }

          final totalSpentOverall = snapshot.data?['totalSpentOverall'] ?? 0.0;
          final totalSpentByIndividual =
              snapshot.data?['totalSpentByIndividual'] ?? {};

          return ListView(
            children: [
              // Total amount spent overall
              ListTile(
                title: const Text('Total Amount Spent Overall'),
                trailing: Text('₹${totalSpentOverall.toStringAsFixed(2)}'),
              ),

              const Divider(),

              // Individual member expenses
              const ListTile(
                title: Text('Individual Expense Breakdown'),
              ),
              ...totalSpentByIndividual.keys.map((memberId) {
                double spent = totalSpentByIndividual[memberId] ?? 0.0;

                return FutureBuilder<String>(
                  future: _getMemberName(memberId),
                  builder: (context, nameSnapshot) {
                    if (nameSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const ListTile(title: Text('Loading...'));
                    }

                    if (nameSnapshot.hasError) {
                      return ListTile(
                        title: Text('Error: ${nameSnapshot.error}'),
                      );
                    }

                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ListTile(
                        title: Text(nameSnapshot.data ?? 'Unknown'),
                        subtitle:
                            Text('Total Spent: ₹${spent.toStringAsFixed(2)}'),
                      ),
                    );
                  },
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }
}
