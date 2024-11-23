import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool isSignup = false;

  // Toggle between login and signup
  void toggleForm() {
    setState(() {
      isSignup = !isSignup;
    });
  }

  // Handle the form submission for login or signup
  Future<void> handleAuth() async {
    try {
      if (isSignup) {
        // Sign Up logic
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
        // After sign up, update the display name
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          user.updateDisplayName(_nameController.text);
        }
      } else {
        // Login logic
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Error"),
          content: Text(e.toString()),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK"),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isSignup ? 'Sign Up' : 'Login'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            if (isSignup)
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Display Name'),
              ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: handleAuth,
              child: Text(isSignup ? 'Sign Up' : 'Login'),
            ),
            TextButton(
              onPressed: toggleForm,
              child: Text(isSignup
                  ? 'Already have an account? Login'
                  : 'Don\'t have an account? Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}
