import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a member
  Future<void> addMember(String name) async {
    await _firestore.collection('members').add({'name': name});
  }

  // Fetch all members
  Stream<QuerySnapshot> getMembers() {
    return _firestore.collection('members').snapshots();
  }

  // Add an expense
  Future<void> addExpense(Map<String, dynamic> expenseData) async {
    await _firestore.collection('expenses').add(expenseData);
  }

  // Fetch all expenses
  Stream<QuerySnapshot> getExpenses() {
    return _firestore.collection('expenses').snapshots();
  }

  // Reset all collections (delete all documents)
  Future<void> resetAllCollections() async {
    try {
      // Fetch all collections
      final collections = await _firestore.collection('members').get();
      final expenses = await _firestore.collection('expenses').get();
      final debts = await _firestore.collection('debts').get();

      // Delete all documents in the 'members' collection
      for (var doc in collections.docs) {
        await doc.reference.delete();
      }

      // Delete all documents in the 'expenses' collection
      for (var doc in expenses.docs) {
        await doc.reference.delete();
      }

      // Delete all documents in the 'debts' collection
      for (var doc in debts.docs) {
        await doc.reference.delete();
      }

      print('All collections have been reset successfully.');
    } catch (e) {
      print('Error during reset: $e');
      rethrow;
    }
  }
}
