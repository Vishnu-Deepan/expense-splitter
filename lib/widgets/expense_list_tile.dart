import 'package:flutter/material.dart';
import '../models/expense.dart';

class ExpenseListTile extends StatelessWidget {
  final Expense expense;

  const ExpenseListTile({Key? key, required this.expense}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(expense.title, style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Amount: \$${expense.amount.toStringAsFixed(2)}'),
          Text('Paid By: ${expense.paidBy}'),
          Text('Involved: ${expense.involved.join(', ')}'),
        ],
      ),
      leading: CircleAvatar(
        child: Text(
          '\$${expense.amount.toStringAsFixed(0)}',
          style: TextStyle(fontSize: 14),
        ),
        backgroundColor: Colors.blueAccent,
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: 16),
    );
  }
}
