import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/save_pdf.dart';

class ExpenseAnalysisScreen extends StatefulWidget {
  const ExpenseAnalysisScreen({super.key});

  @override
  _ExpenseAnalysisScreenState createState() => _ExpenseAnalysisScreenState();
}

class _ExpenseAnalysisScreenState extends State<ExpenseAnalysisScreen> {
  final String? userId = FirebaseAuth.instance.currentUser?.uid;
  late Future<Map<String, dynamic>> reportData;

  // Fetch data from Firestore for the user
  Future<Map<String, dynamic>> fetchData() async {
    Map<String, dynamic> report = {};

    var membersSnapshot = await FirebaseFirestore.instance
        .collection('members')
        .where('userId', isEqualTo: userId)
        .get();

    report['members'] = membersSnapshot.docs.map((doc) => doc['name']).toList();

    var individualExpenseSnapshot = await FirebaseFirestore.instance
        .collection('individualExpense')
        .where('userId', isEqualTo: userId)
        .get();

    report['individualExpenses'] = individualExpenseSnapshot.docs
        .map((doc) => {
              'memberId': doc.id,
              'initialPay': doc['initialPay'],
              'debtPay': doc['debtPay'],
            })
        .toList();

    var expensesSnapshot = await FirebaseFirestore.instance
        .collection('expenses')
        .where('userId', isEqualTo: userId)
        .get();

    report['sharedExpenses'] = expensesSnapshot.docs
        .map((doc) => {
              'title': doc['title'],
              'amount': doc['amount'],
              'paidBy': doc['payerId'],
            })
        .toList();

    var debtsSnapshot = await FirebaseFirestore.instance
        .collection('debts')
        .where('userId', isEqualTo: userId)
        .get();

    report['debts'] = debtsSnapshot.docs
        .map((doc) => {
              'docId': doc.id,
              'totalDebt': doc['totalDebt'],
              'debts': Map<String, dynamic>.from(doc['debts']),
            })
        .toList();

    return report;
  }

  // Define a function to get the total number of members
  Future<int> getTotalMembers() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('members')
        .where('userId', isEqualTo: userId)
        .get();
    return snapshot.docs.length; // Return the total count of members
  }

// Define a function to calculate the total shared expense
  double calculateTotalExpense(List<dynamic> sharedExpenses) {
    double totalExpense = 0.0;
    for (var expense in sharedExpenses) {
      totalExpense += expense['amount'];
    }
    return totalExpense;
  }

  Future<String> _getMemberName(String memberId) async {
    final doc = await FirebaseFirestore.instance
        .collection('members')
        .doc(memberId)
        .get();
    return doc.data()?['name'] ?? 'Unknown';
  }

  Future<List<Map<String, dynamic>>> _getSortedDebts(
      List<dynamic> debts) async {
    // Fetch the names for each debt
    Map<String, String> memberNames = {};

    // Fetch names for each member only once (avoiding multiple API calls)
    for (var debt in debts) {
      if (!memberNames.containsKey(debt['docId'])) {
        String name = await _getMemberName(debt['docId']);
        memberNames[debt['docId']] = name;
      }
    }

    // Now that we have all the names, we can sort the debts by the member names
    List<Map<String, dynamic>> sortedDebts = List.from(debts);

    sortedDebts.sort((a, b) {
      String nameA = memberNames[a['docId']] ?? '';
      String nameB = memberNames[b['docId']] ?? '';
      return nameA.compareTo(nameB); // Synchronously compare names
    });

    return sortedDebts;
  }

  @override
  void initState() {
    super.initState();

    reportData = fetchData();
  }

  bool isLoading = false; // Track loading state

  // Method to fetch data and export to PDF
  Future<void> handleExport() async {
    setState(() {
      isLoading = true; // Set loading to true when action starts
    });

    try {
      final report = await fetchData(); // Fetch the data
      await exportToPDF(report); // Export to PDF
    } catch (e) {
      print("Error during export: $e");
    } finally {
      setState(() {
        isLoading = false; // Set loading to false once action finishes
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: isLoading ? null : handleExport, // Disable if loading
        child: isLoading
            ? const CircularProgressIndicator(
                color: Colors.white,
              )
            : const Icon(Icons.share_outlined),
      ),
      appBar: AppBar(
        title: const Text('Expense Report'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: reportData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          var report = snapshot.data;

          if (report == null) {
            return const Center(child: Text('No data available.'));
          }

          String currentDateTime = DateTime.now().toString().substring(0, 19);

          // Get total expense and number of members
          double totalExpense = calculateTotalExpense(report['sharedExpenses']);
          Future<int> totalMembersFuture = getTotalMembers();

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Report generation date and time
                  Card(
                    elevation: 4, // Giving a card-like elevation
                    margin: const EdgeInsets.only(bottom: 20),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Report generated on: $currentDateTime',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                      ),
                    ),
                  ),

                  // Total Expense and Split Amount
                  FutureBuilder<int>(
                    future: totalMembersFuture,
                    builder: (context, memberSnapshot) {
                      if (memberSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (memberSnapshot.hasError) {
                        return Center(
                            child: Text('Error: ${memberSnapshot.error}'));
                      }

                      int totalMembers =
                          memberSnapshot.data ?? 1; // Default to 1 if no data
                      double splitAmount = totalExpense / totalMembers;

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Total Expense Display
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'Total Expense:',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors
                                      .grey, // Lighter color for the title
                                ),
                              ),
                              Text(
                                '₹${totalExpense.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors
                                      .green, // Highlight the rupee amount
                                ),
                              ),
                            ],
                          ),

                          // Amount to be Split Display
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                '₹${splitAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors
                                      .green, // Highlight the rupee amount
                                ),
                              ),
                              const Text(
                                'per person',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors
                                      .grey, // Lighter color for the label
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Shared Expenses Section with Card widget
                  Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    color: Colors.blueAccent.withOpacity(0.1),
                    // Light blue background
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Expenses History:',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color:
                                      Colors.blueGrey, // Darker color for title
                                ),
                          ),
                          const SizedBox(height: 10),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Title')),
                                DataColumn(label: Text('Amount')),
                                DataColumn(label: Text("Paid By"))
                              ],
                              rows: report['sharedExpenses']
                                  .map<DataRow>((expense) {
                                return DataRow(cells: [
                                  DataCell(Text(expense['title'])),
                                  DataCell(Text(
                                    '${expense['amount']}',
                                    style: const TextStyle(
                                        color:
                                            Colors.green), // Green for amount
                                  )),
                                  // Use FutureBuilder for 'Paid By' column
                                  DataCell(FutureBuilder<String>(
                                    future: _getMemberName(expense['paidBy']),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Text('Loading...');
                                      } else if (snapshot.hasError) {
                                        return const Text('Error');
                                      } else if (snapshot.hasData) {
                                        return Text(
                                            snapshot.data!); // Display the name
                                      } else {
                                        return const Text(
                                            'Unknown'); // Fallback if no data
                                      }
                                    },
                                  )),
                                ]);
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Individual Expenses Section with Card widget
                  Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    color: Colors.orangeAccent.withOpacity(0.1),
                    // Light orange background
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Individual Expenses:',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color:
                                      Colors.orange, // Orange color for title
                                ),
                          ),
                          const SizedBox(height: 10),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Member')),
                                DataColumn(label: Text('Paid')),
                                DataColumn(label: Text('Debt Paid')),
                                DataColumn(label: Text('Total Expense')),
                              ],
                              rows: report['individualExpenses']
                                  .map<DataRow>((expense) {
                                return DataRow(cells: [
                                  DataCell(FutureBuilder<String>(
                                    future: _getMemberName(expense['memberId']),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Text('Loading...');
                                      } else if (snapshot.hasError) {
                                        return const Text('Error');
                                      } else if (snapshot.hasData) {
                                        return Text(snapshot.data!);
                                      }
                                      return const Text('Unknown');
                                    },
                                  )),
                                  DataCell(Text(
                                    '${expense['initialPay']}',
                                    style: const TextStyle(
                                        color: Colors.blue), // Blue for paid
                                  )),
                                  DataCell(Text(
                                    '${expense['debtPay']}',
                                    style: const TextStyle(
                                        color: Colors.red), // Red for debt paid
                                  )),
                                  DataCell(Text(
                                    '${expense['initialPay'] + expense['debtPay']}',
                                    style: const TextStyle(
                                        color: Colors.green), // Green for total
                                  )),
                                ]);
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Debts Section with Card widget
                  Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    color: Colors.tealAccent.withOpacity(0.1),
                    // Light teal background
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Debts:',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.teal, // Teal color for title
                                ),
                          ),
                          const SizedBox(height: 10),
                          FutureBuilder<List<Map<String, dynamic>>>(
                            future: _getSortedDebts(report['debts']),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }
                              if (snapshot.hasError) {
                                return Center(
                                    child: Text('Error: ${snapshot.error}'));
                              }
                              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return const Center(
                                    child: Text('No debts available.'));
                              }

                              var sortedDebts = snapshot.data!;

                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columns: const [
                                    DataColumn(label: Text('Member')),
                                    DataColumn(label: Text('Pay To')),
                                    DataColumn(label: Text('Amount')),
                                  ],
                                  rows: sortedDebts.map<DataRow>((debt) {
                                    return DataRow(cells: [
                                      DataCell(FutureBuilder<String>(
                                        future: _getMemberName(debt['docId']),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const Text('Loading...');
                                          } else if (snapshot.hasError) {
                                            return const Text('Error');
                                          } else if (snapshot.hasData) {
                                            return Text(snapshot.data!);
                                          }
                                          return const Text('Unknown');
                                        },
                                      )),
                                      DataCell(FutureBuilder<String>(
                                        future: _getMemberName(
                                            debt['debts'].keys.first),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const Text('Loading...');
                                          } else if (snapshot.hasError) {
                                            return const Text('Error');
                                          } else if (snapshot.hasData) {
                                            return Text(snapshot.data!);
                                          }
                                          return const Text('Unknown');
                                        },
                                      )),
                                      DataCell(Text(
                                        '${debt['totalDebt']}',
                                        style: const TextStyle(
                                            color: Colors
                                                .red), // Red for debt amount
                                      )),
                                    ]);
                                  }).toList(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
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
}
