import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class AddMemberScreen extends StatefulWidget {
  final bool isMembersAdded; // Flag to check if members are added
  final Function(bool) onMembersAdded; // Callback to send updated flag back

  const AddMemberScreen(
      {super.key, required this.isMembersAdded, required this.onMembersAdded});

  @override
  _AddMemberScreenState createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final FirebaseService firebaseService = FirebaseService();
  final TextEditingController _totalMembersController = TextEditingController();
  List<TextEditingController> _memberControllers = [];
  int? _totalMembers;

  // Function to add member fields dynamically
  void _generateMemberFields() {
    setState(() {
      _memberControllers = List.generate(
        _totalMembers!,
        (_) => TextEditingController(),
      );
    });
  }

  // Function to add all members to Firebase
  Future<void> _addMembersToFirebase() async {
    for (var controller in _memberControllers) {
      final name = controller.text.trim();
      if (name.isNotEmpty) {
        await firebaseService.addMember(name);
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All members added successfully!')),
    );
    widget.onMembersAdded(true); // Update the flag to true

    // Close this screen and send updated flag back to previous page
    Navigator.pop(context);
  }

  // Show confirmation dialog to verify the entered data
  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Members"),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Please confirm the members you've added:"),
              const SizedBox(height: 16),
              for (int i = 0; i < _totalMembers!; i++)
                Text("${i + 1}. ${_memberControllers[i].text.trim()}"),
              const SizedBox(height: 16),
              const Text("Is everything correct?"),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
              child: const Text('Edit'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _addMembersToFirebase(); // Confirm and add to Firebase
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Members')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Input for the total number of members
            TextField(
              controller: _totalMembersController,
              decoration:
                  const InputDecoration(labelText: 'Total Number of Members'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final total = int.tryParse(_totalMembersController.text.trim());
                if (total != null && total > 0 && !widget.isMembersAdded) {
                  setState(() {
                    _totalMembers = total;
                  });
                  _generateMemberFields();
                } else if (widget.isMembersAdded) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Members have already been added!')),
                  );
                }
              },
              child: const Text('Generate Member Fields'),
            ),
            const SizedBox(height: 16),
            // Show the dynamic member fields and the button to save them
            if (_totalMembers != null && !widget.isMembersAdded) ...[
              for (int i = 0; i < _totalMembers!; i++) ...[
                TextField(
                  controller: _memberControllers[i],
                  decoration:
                      InputDecoration(labelText: 'Member ${i + 1} Name'),
                ),
                const SizedBox(height: 8),
              ],
              ElevatedButton(
                onPressed: _showConfirmationDialog,
                child: const Text('Confirm and Add Members'),
              ),
            ] else if (widget.isMembersAdded) ...[
              const Text(
                'All members have been added. Reset the trip to add new members.',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
