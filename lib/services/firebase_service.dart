import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add a member
  Future<void> addMember(String name) async {
    try {
      // Get current user's UID
      String? userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception("User is not logged in");
      }

      // Add member with userId
      await _firestore.collection('members').add({
        'name': name,
        'userId': userId, // Associate the member with the logged-in user
      });
    } catch (e) {
      print('Error adding member: $e');
      rethrow;
    }
  }

  // Fetch all members for the logged-in user
  Stream<QuerySnapshot> getMembers() {
    String? userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception("User is not logged in");
    }
    // Fetch members associated with the logged-in user
    return _firestore
        .collection('members')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  // Add an expense
  Future<void> addExpense(Map<String, dynamic> expenseData) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception("User is not logged in");
      }

      // Add expense with payerId and sharedWith containing the logged-in user ID
      await _firestore.collection('expenses').add({
        'payerId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'title': expenseData['title'],
        'amount': expenseData['amount'],
        'sharedWith': [userId, ...expenseData['sharedWith']],
      });
    } catch (e) {
      print('Error adding expense: $e');
      rethrow;
    }
  }

  // Fetch all expenses for the logged-in user
  Stream<QuerySnapshot> getExpenses() {
    String? userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception("User is not logged in");
    }

    // Fetch expenses that are shared with the logged-in user
    return _firestore
        .collection('expenses')
        .where('sharedWith', arrayContains: userId)
        .snapshots();
  }

  // Reset all collections (delete all documents)
  Future<void> resetAllCollections() async {
    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;

      final snapshot = await _firestore
          .collection('expenses')
          .where("userId", isEqualTo: userId)
          .get();
      // Fetch all collections
      final collections = await _firestore
          .collection('members')
          .where("userId", isEqualTo: userId)
          .get();
      final expenses = await _firestore
          .collection('expenses')
          .where("userId", isEqualTo: userId)
          .get();
      final debts = await _firestore
          .collection('debts')
          .where("userId", isEqualTo: userId)
          .get();
      final individualExpense = await _firestore
          .collection('individualExpense')
          .where("userId", isEqualTo: userId)
          .get();

      // Reference the user's document in the 'users' collection
      DocumentReference userDocRef =
          FirebaseFirestore.instance.collection('users').doc(userId);

      // Update the 'membersAdded' field to false
      await userDocRef.update({
        'membersAdded': false, // Set membersAdded to false
      });

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

      // Delete all documents in the 'individualExpense' collection
      for (var doc in individualExpense.docs) {
        await doc.reference.delete();
      }

      print('All collections have been reset successfully.');
    } catch (e) {
      print('Error during reset: $e');
      rethrow;
    }
  }
}
