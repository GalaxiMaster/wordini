import 'dart:async';
import 'package:wordini/Pages/home.dart';
import 'package:wordini/Pages/Account/sign_up.dart';
import 'package:wordini/encryption_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:wordini/file_handling.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  SignInPageState createState() => SignInPageState();
}

class SignInPageState extends State<SignInPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final EncryptionService _encryptionService = EncryptionService.instance;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _authSub;

  @override
  void initState() {
    super.initState();
    GoogleSignIn.instance
        .initialize(
      serverClientId: dotenv.get('serverClientId'),
    ).then((_) {
      _authSub = GoogleSignIn.instance.authenticationEvents.listen(
        (event) async {
          if (event is GoogleSignInAuthenticationEventSignIn) {
            final GoogleSignInAccount user = event.user;
            try {
              // The API surface for the plugin exposes a synchronous
              // `authentication` object on the account in this version.
              final GoogleSignInAuthentication authentication = user.authentication;

              final credential = GoogleAuthProvider.credential(
                idToken: authentication.idToken,
              );

              UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
              debugPrint(authentication.idToken);
              debugPrint('Firebase sign-in complete for ${user.email}');
              bool isNew = userCredential.additionalUserInfo?.isNewUser ?? false;
              _encryptionService.writeToSecureStorage(key: 'authIdToken', value: _encryptionService.encrypt(authentication.idToken ?? ''));
              if (isNew) {
                createDefaultPermissions(userCredential);
              }
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/home');
              }
            } catch (e, st) {
              debugPrint('Error handling authentication event: $e');
              debugPrint('$st');
            }
          }
        },
        onError: (e) => debugPrint('Authentication event error: $e'),
      );
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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
              // Form fields with max width constraint
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: AutofillGroup(
                  child: Column(
                    children: [
                      TextField(
                        controller: _emailController,
                        autofillHints: const [AutofillHints.email],
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
                      const SizedBox(height: 20),
                      TextField(
                        controller: _passwordController,
                        autofillHints: const [AutofillHints.password],
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
                    ],
                  ),
                ),
              ),
                            
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          if (_emailController.text.isEmpty ||
                              _passwordController.text.isEmpty) {
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
                            getUserPermissions();
                            if (!context.mounted) return;
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const HomePage()),
                            );
                            _encryptionService.writeToSecureStorage(
                                key: 'password',
                                value: _encryptionService
                                    .encrypt(_passwordController.text));
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
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              errorSnackBar(message),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              errorSnackBar('An unexpected error occurred: $e'),
                            );
                          }
                        },
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Sign In',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => SignUpPage()),
                        );
                      },
                      child: Text(
                        'Don\'t have an account? Sign up',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.white24)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.white24)),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            await GoogleSignIn.instance.initialize(
                              serverClientId: dotenv.get('serverClientId'),
                            );
                            await GoogleSignIn.instance.authenticate();
                          } on GoogleSignInException catch (e) {
                            debugPrint(
                                'Error signing in with Google: ${e.code} ${e.description}');
                          } catch (e, st) {
                            debugPrint('Unexpected error signing in with Google: $e');
                            debugPrint('$st');
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Colors.white38, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: Image.asset(
                          'assets/google_logo.png',
                          height: 20,
                          width: 20,
                        ),
                        label: const Text(
                          'Sign in with Google',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                )
              ),
            ],
          ),
        ),
      ),
    );
  }
}

SnackBar errorSnackBar(text) => SnackBar(
    backgroundColor: const Color.fromRGBO(21, 21, 21, 1),
    content: Text(
      text,
      style: const TextStyle(
        color: Colors.red,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    ));
