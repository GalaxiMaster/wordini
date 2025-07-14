import 'package:wordini/Pages/home.dart';
import 'package:wordini/Pages/Account/sign_up.dart';
import 'package:wordini/encryption_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final EncryptionService _encryptionService = EncryptionService.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26),
          child: Column(
            spacing: 25,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Colors.white38,
                      width: 2,
                    ),
                  ),
                ),
              ),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Colors.white38,
                      width: 2,
                    ),
                  ),
                ),
                obscureText: true,
              ),
              Column(
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      // Input validation
                      if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          errorSnackBar('Please fill in all fields'),
                        );
                        return;
                      }
                  
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          errorSnackBar('Invalid email format'),
                        );
                        return;
                      }
                      try {
                        await _auth.signInWithEmailAndPassword(
                          email: _emailController.text.trim(),
                          password: _passwordController.text,
                        );
                        if (!context.mounted) return;
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const HomePage()),
                        );
                        _encryptionService.writeToSecureStorage(key: 'password', value: _encryptionService.encrypt(_passwordController.text));
                      } on FirebaseAuthException catch (e) {
                        String message;
                        switch (e.code) {
                          case 'invalid-credential':
                            message = 'Invalid Email or Password';
                            break;
                          case 'user-not-found':
                            message = 'Invalid Email or Password';
                            break;
                          case 'invalid-email':
                            message = 'Invalid email format';
                            break;
                          case 'user-disabled':
                            message = 'This account has been disabled';
                            break;
                          default:
                            message = 'An error occurred: ${e.message}';
                        }
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          errorSnackBar(message),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          errorSnackBar('An unexpected error occurred: $e'),
                        );
                      }                
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 100),
                      child: Text('Sign In'),
                    ),
                  ),
                  GestureDetector(
                    onTap: (){
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => SignUpPage()),
                      );
                    },
                    child: const Text(
                      'Don\'t have an account?',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}  
SnackBar errorSnackBar(text) =>  SnackBar(
  backgroundColor: const Color.fromRGBO(21, 21, 21, 1),
  content: Text(
    text,
    style: const TextStyle(
      color: Colors.red,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    ),
  )
);