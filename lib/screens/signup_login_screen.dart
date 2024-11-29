import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool isSignup = false;
  bool isLoading = false;

  // Toggle between login and signup
  void toggleForm() {
    setState(() {
      isSignup = !isSignup;
    });
  }

  // Handle the form submission for login or signup
  Future<void> handleAuth() async {
    setState(() {
      isLoading = true;
    });

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
          title: const Text("Error", style: TextStyle(color: Colors.white)),
          content:
              Text(e.toString(), style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.grey[850],
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child:
                  const Text("OK", style: TextStyle(color: Colors.blueAccent)),
            )
          ],
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          isSignup ? 'Sign Up' : 'Login',
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              color: Colors.grey[900],
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (isSignup)
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Name',
                          labelStyle: const TextStyle(color: Colors.white),
                          prefixIcon:
                              const Icon(Icons.person, color: Colors.white),
                          filled: true,
                          fillColor: Colors.grey[800],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: const TextStyle(color: Colors.white),
                        prefixIcon:
                            const Icon(Icons.email, color: Colors.white),
                        filled: true,
                        fillColor: Colors.grey[800],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: const TextStyle(color: Colors.white),
                        prefixIcon: const Icon(Icons.lock, color: Colors.white),
                        filled: true,
                        fillColor: Colors.grey[800],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      obscureText: true,
                    ),
                    const SizedBox(height: 20),
                    isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: handleAuth,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                              backgroundColor: Colors.blueAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              isSignup ? 'Sign Up' : 'Login',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: toggleForm,
                      child: Text(
                        isSignup
                            ? 'Already have an account? Login'
                            : 'Don\'t have an account? Sign Up',
                        style: const TextStyle(
                          color: Colors.blueAccent,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
