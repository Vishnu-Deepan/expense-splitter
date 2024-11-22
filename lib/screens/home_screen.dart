import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:shared_preferences/shared_preferences.dart'; // For shared preferences
import 'add_member_screen.dart';
import 'add_expense_screen.dart';
import 'settle_debt_screen.dart';
import '../services/firebase_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService firebaseService = FirebaseService();
  final TextEditingController _confirmationController = TextEditingController();
  bool _membersAdded = false; // To track if members are added

  // Function to load _membersAdded value from SharedPreferences
  void _loadMembersAdded() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _membersAdded = prefs.getBool('membersAdded') ?? false;
    });
  }

  // Function to save _membersAdded value to SharedPreferences
  void _saveMembersAdded() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('membersAdded', _membersAdded);
  }

  @override
  void initState() {
    super.initState();
    _loadMembersAdded(); // Load _membersAdded value when the screen is initialized
  }

  // Function to reset the trip (delete all collections)
  Future<void> _resetTrip(BuildContext context) async {
    if (_confirmationController.text.toLowerCase() != "confirm") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please type "confirm" to reset the trip.')),
      );
      return;
    }
    _confirmationController.text = "";

    try {
      // Delete all documents from each collection
      await firebaseService.resetAllCollections();

      // Show a confirmation message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trip has been reset. All data deleted.')),
      );
      setState(() {
        _membersAdded = false;
      });

      // Save the updated _membersAdded value to SharedPreferences
      _saveMembersAdded();

      // Optionally, navigate back or reset the app to its initial state
      Navigator.popUntil(context,
          (route) => route.isFirst); // Navigate to the first route in the stack
      Navigator.pop(context);
    } catch (e) {
      print('Error during trip reset: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reset trip: $e')),
      );
    }
  }

  // Function to fetch members' names based on IDs
  Future<Map<String, String>> _getMembersNames(List<String> memberIds) async {
    Map<String, String> memberNames = {};

    try {
      // Fetch members' data
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('members')
          .where(FieldPath.documentId, whereIn: memberIds)
          .get();

      // Map member IDs to their respective names
      for (var doc in snapshot.docs) {
        memberNames[doc.id] =
            doc['name']; // Assuming 'name' field is in the 'members' collection
      }
    } catch (e) {
      print('Error fetching member names: $e');
    }

    return memberNames;
  }

  // Function to fetch expenses data from Firestore
  Stream<List<Map<String, dynamic>>> _getExpensesStream() {
    return FirebaseFirestore.instance
        .collection('expenses')
        .orderBy('timestamp') // Order by timestamp to show in correct order
        .snapshots()
        .map((snapshot) {
      List<Map<String, dynamic>> expenses = [];
      for (var doc in snapshot.docs) {
        expenses.add(doc.data() as Map<String, dynamic>);
      }
      return expenses;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: () {
                _showResetConfirmationDialog(context);
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Icon(Icons.delete_sweep_outlined),
                  Text("Reset Trip"),
                ],
              ),
            ),
          ],
        ),
      ),
      appBar: AppBar(title: const Text('Expense Splitter')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Only show Add Members button if members are not added yet
            if (!_membersAdded) ...[
              ElevatedButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddMemberScreen(
                        isMembersAdded: _membersAdded,
                        onMembersAdded: (bool updated) {
                          setState(() {
                            _membersAdded = updated; // Update the flag
                            _saveMembersAdded(); // Save to shared preferences
                          });
                        },
                      ),
                    ),
                  );
                },
                child: const Text('Add Members'),
              ),
            ],
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddExpenseScreen()),
              ),
              child: const Text('Add Expenses'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SettleDebtScreen()),
              ),
              child: const Text('Settle Debts'),
            ),
            const SizedBox(height: 20),

            // Display Expenses in Cards
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _getExpensesStream(),
              // Fetch expenses using StreamBuilder
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('No expenses found');
                } else {
                  List<Map<String, dynamic>> expenses = snapshot.data!;

                  // Extract all member IDs from the expenses to fetch names
                  Set<String> memberIds = {};
                  for (var expense in expenses) {
                    memberIds.add(expense['payerId']);
                    memberIds.addAll(List<String>.from(expense['sharedWith']));
                  }

                  // Fetch the names of all members involved
                  return FutureBuilder<Map<String, String>>(
                    future: _getMembersNames(memberIds.toList()),
                    builder: (context, membersSnapshot) {
                      if (membersSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else if (membersSnapshot.hasError) {
                        return Text(
                            'Error fetching member names: ${membersSnapshot.error}');
                      } else if (!membersSnapshot.hasData ||
                          membersSnapshot.data!.isEmpty) {
                        return const Text('No member names found');
                      } else {
                        Map<String, String> memberNames = membersSnapshot.data!;

                        // Display expenses using member names instead of IDs
                        return Expanded(
                          child: ListView.builder(
                            itemCount: expenses.length,
                            itemBuilder: (context, index) {
                              var expense = expenses[index];

                              return Card(
                                elevation: 5,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        DateFormat.yMMMd().format(
                                                expense['timestamp']
                                                    .toDate()) ??
                                            'N/A',
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Amount: ₹${expense['amount'].toString()}',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Payer: ${memberNames[expense['payerId']] ?? 'Unknown'}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Shared With: ${expense['sharedWith'].map((id) => memberNames[id] ?? 'Unknown').join(', ')}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Title: ${expense['title']}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      }
                    },
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // Dialog to confirm the reset
  void _showResetConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Type "confirm" to reset'),
          content: TextField(
            controller: _confirmationController,
            decoration: const InputDecoration(hintText: 'Type "confirm"'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _resetTrip(
                    context); // Reset the trip if the confirmation is valid
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }
}
