import 'package:expense_splitter/screens/expense_analysis_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
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

  // Function to load _membersAdded value from Firestore
  void _loadMembersAdded() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Fetch the flag for the logged-in user from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists && userDoc['membersAdded'] != null) {
        setState(() {
          _membersAdded = userDoc['membersAdded'];
        });
      }
    } catch (e) {
      print('Error fetching membersAdded flag: $e');
    }
  }

  // Function to save _membersAdded value to Firestore
  void _saveMembersAdded() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Save the flag to Firestore for the current user
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'membersAdded': _membersAdded}, SetOptions(merge: true));
    } catch (e) {
      print('Error saving membersAdded flag: $e');
    }
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

      // Save the updated _membersAdded value to Firestore
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
      // Fetch members' data from Firestore using the current logged-in user ID
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception("User is not logged in");
      }

      // Fetch only the members that belong to the logged-in user
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('members')
          .where('userId', isEqualTo: userId) // Filter by userId
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
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      throw Exception("User is not logged in");
    }

    return FirebaseFirestore.instance
        .collection('expenses')
        .where('userId',
            isEqualTo:
                userId) // Filter expenses that involve the logged-in user
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
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      drawer: Drawer(
        backgroundColor: Colors.grey[900],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(
              height: 20,
            ),
            Text(
              user != null && user.displayName != null
                  ? user.displayName!
                  : "Welcome",
              style: const TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.deepPurple,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddExpenseScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Expense',
          style: TextStyle(
            fontSize: 20,
          ),
        ),
      ),
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: Colors.white, // Change the drawer (hamburger) icon color here
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black, Colors.grey[850]!], // Matching gradient
              end: Alignment.topCenter,
              begin: Alignment.bottomCenter,
            ),
          ),
        ),
        centerTitle: true,
        title: const Text(
          'Expense Splitter',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              // Show a confirmation dialog before signing out
              await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Sign Out'),
                    content: const Text('Are you sure you want to sign out?'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(false); // User canceled
                        },
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.of(context).pop(true); // User confirmed
                          await FirebaseAuth.instance.signOut();
                        },
                        child: const Text('Yes'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Colors.grey[850]!], // Dark to grey gradient
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Only show Add Members button if members are not added yet
              if (!_membersAdded) ...[
                Material(
                  elevation: 7.0,
                  borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                  child: InkWell(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddMemberScreen(
                            isMembersAdded: _membersAdded,
                            onMembersAdded: (bool updated) {
                              setState(() {
                                _membersAdded = updated; // Update the flag
                                _saveMembersAdded(); // Save to Firestore
                              });
                            },
                          ),
                        ),
                      );
                    },
                    child: Ink(
                      decoration: const BoxDecoration(
                        gradient:
                            LinearGradient(colors: [Colors.red, Colors.pink]),
                        borderRadius: BorderRadius.all(Radius.circular(10.0)),
                      ),
                      height: 60, // Increased height
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(width: 48),
                          Expanded(
                            child: Center(
                              child: Text(
                                'Add Members',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  // Make text bold
                                  color: Colors.white,
                                  // Text color for contrast
                                  fontSize:
                                      16, // Adjust font size for better visibility
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 48.0,
                            child: Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 23.0,
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(
                height: 20,
              ),

              Material(
                elevation: 7.0,
                borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SettleDebtScreen()),
                  ),
                  child: Ink(
                    decoration: const BoxDecoration(
                      gradient:
                          LinearGradient(colors: [Colors.blue, Colors.green]),
                      borderRadius: BorderRadius.all(Radius.circular(10.0)),
                    ),
                    height: 60, // Increased height
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(width: 48),
                        Expanded(
                          child: Center(
                            child: Text(
                              'Settle Debts',
                              style: TextStyle(
                                fontWeight: FontWeight.bold, // Make text bold
                                color: Colors.white, // Text color for contrast
                                fontSize:
                                    16, // Adjust font size for better visibility
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 48.0,
                          child: Icon(
                            Icons.attach_money,
                            color: Colors.white,
                            size: 23.0,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Material(
                elevation: 7.0,
                borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ExpenseAnalysisScreen()),
                  ),
                  child: Ink(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          colors: [Colors.orangeAccent, Colors.orange]),
                      borderRadius: BorderRadius.all(Radius.circular(10.0)),
                    ),
                    height: 60, // Increased height
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(width: 48),
                        Expanded(
                          child: Center(
                            child: Text(
                              'Expense Analysis',
                              style: TextStyle(
                                fontWeight: FontWeight.bold, // Make text bold
                                color: Colors.white, // Text color for contrast
                                fontSize:
                                    16, // Adjust font size for better visibility
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 48.0,
                          child: Icon(
                            Icons.pie_chart,
                            color: Colors.white,
                            size: 23.0,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
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
                      memberIds
                          .addAll(List<String>.from(expense['sharedWith']));
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
                          Map<String, String> memberNames =
                              membersSnapshot.data!;

                          // Display expenses using member names instead of IDs
                          return Expanded(
                            child: ListView.builder(
                              itemCount: expenses.length,
                              itemBuilder: (context, index) {
                                var expense = expenses[index];

                                return Card(
                                  elevation: 3,
                                  // Lower elevation for a more subtle shadow
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        16), // More rounded for a modern feel
                                  ),
                                  color: Colors.grey[850],
                                  // Dark background color
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    // Increased padding for a more spacious layout
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Title and Amount come first
                                        Text(
                                          textAlign: TextAlign.center,
                                          '${expense['title']}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            // White text for contrast
                                            fontSize: 18,
                                            // Larger font for the title
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Amount: ₹${expense['amount'].toString()}',
                                          style: const TextStyle(
                                            color: Colors.greenAccent,
                                            // A distinct color for the amount
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 12),

                                        // Time and Date
                                        Text(
                                          '${DateFormat.yMMMd().format(expense['timestamp'].toDate())} at ${DateFormat.Hm().format(expense['timestamp'].toDate())}',
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            // Lighter grey for less emphasis
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 12),

                                        // Payer Info
                                        Text(
                                          'Payer: ${memberNames[expense['payerId']] ?? 'Unknown'}',
                                          style: TextStyle(
                                            color: Colors.grey[300],
                                            // Slightly lighter grey for details
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 8),

                                        // Shared With
                                        Text(
                                          'Shared With: ${expense['sharedWith'].map((id) => memberNames[id] ?? 'Unknown').join(', ')}',
                                          style: TextStyle(
                                            color: Colors.grey[300],
                                            // Matching grey text for consistency
                                            fontSize: 14,
                                          ),
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
