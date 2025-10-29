import 'dart:async';
import 'package:wordini/Pages/Account/sign_in.dart';
import 'package:wordini/encryption_controller.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wordini/widgets.dart'; // <-- Add this import
final EncryptionService _encryptionService = EncryptionService.instance;

class AccountPage extends StatefulWidget {
  final User accountDetails;
  const AccountPage({super.key, required this.accountDetails});
  @override
  // ignore: library_private_types_in_public_api
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  late User account;
  final EncryptionService encryption = EncryptionService.instance;
  @override
  void initState() {
    account = widget.accountDetails;
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Settings'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Column(
        children: [
          infoBox('Email: ', account.email, Icons.edit, () async {
            try {
              String? newEmail = await showDialog(
                context: context,
                builder: (BuildContext context) => const ChangeEmailDialog(),
              );  
    
              if (newEmail != null) {
                _encryptionService.writeToSecureStorage(key: 'emailChange', value: newEmail);
                if (context.mounted){
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Verification email sent. Please check your email to complete the change.'),
                      duration: Duration(seconds: 5),
                    ),
                  );
                }
              }
            } catch (e) {
              if (context.mounted){
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('An unexpected error occurred: $e')),
                );
              }
            }
          }),
          infoBox('Password: ', '***********', Icons.edit, () async {
            try {
              String? newPass = await showDialog(
                context: context,
                builder: (BuildContext context) => ChangePasswordDialog(),
              );

              if (newPass != null) {
                newPass = newPass.trim();
                if (newPass == '') throw 'Password cannot be empty';
                await reAuthUser(account);
                await account.updatePassword(newPass);
                _encryptionService.writeToSecureStorage(key: 'password', value: encryption.encrypt(newPass));
              }
            } catch (e) {
              if (context.mounted){
                ScaffoldMessenger.of(context).showSnackBar(
                  errorSnackBar(e),
                );
              }
            }
          }),
          GestureDetector(
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              _encryptionService.clearAllSecureStorage ();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.power_settings_new,
                    color: Colors.red,
                    size: 32.5,
                  ),
                  SizedBox(width: 10), // <-- Fix spacing
                  Text(
                    'Sign out',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: GestureDetector(
              onTap: () async {
                final bool res = await showDialog(
                  context: context, 
                  builder: (BuildContext context) {
                    String email = account.email ?? 'Erorr getting email';
                    int lenEmail = email.length;
                    email = email.substring(0, (lenEmail/3-(lenEmail/12).round()).round()) + ('*' * (lenEmail - (lenEmail/3*2).round())) + email.substring((lenEmail/3*2-(lenEmail/12)).round(), lenEmail);
                    TextEditingController controller = TextEditingController();
                    return AlertDialog(
                      title: const Text('Delete Account'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Are you sure you want to delete your account? This action cannot be undone.'),
                          Text(email),
                          TextField(
                            controller: controller,
                            decoration: InputDecoration(
                              labelText: 'Enter your email to confirm',
                            ),
                          )
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            if (controller.text == account.email){
                              Navigator.of(context).pop(true);
                            }else{
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Email does not match')),
                              );
                            }
                          },
                          child: const Text('Delete', style: TextStyle(color: Colors.red),),
                        ),
                      ],
                    );
                  }
                );
                if (res){
                  LoadingOverlay loadingOverlay = LoadingOverlay();
                  if (context.mounted) loadingOverlay.showLoadingOverlay(context);
                  await reAuthUser(account);
                  await FirebaseAuth.instance.currentUser?.delete();
                  await FirebaseAuth.instance.signOut();
                  _encryptionService.clearAllSecureStorage ();
                  loadingOverlay.removeLoadingOverlay();
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.power_settings_new,
                      color: Colors.red,
                      size: 32.5,
                    ),
                    SizedBox(width: 10), // <-- Fix spacing
                    Text(
                      'Delete Account',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget infoBox(String key, String? value, IconData icon, Function function) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      Text(
                        key,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          value ?? '',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 20,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => function(),
                  child: Icon(icon),
                )
              ],
            ),
          ),
          const Divider(color: Colors.white70,),
        ],
      ),
    );
  }
}

Future<void> reAuthUser(User account, {String? email}) async {
  String? emailChange = await _encryptionService.readFromSecureStorage(key: 'emailChange');
  try {
    String? oldPass = await _encryptionService.readFromSecureStorage(key: 'password');
    if (account.email == null) throw 'Somehow your account doesnt have an email';
    if (oldPass == null) throw 'Failed to fetch auth details';

    String decryptedPass = _encryptionService.decrypt(oldPass); // Add error handling here
    AuthCredential credential = EmailAuthProvider.credential(
      email: email ?? account.email ?? '', 
      password: decryptedPass
    );
    await account.reauthenticateWithCredential(credential);

  } catch (e) {
    if (e is FirebaseAuthException){
      if (email == null && emailChange != null){
        if (e.code == "user-not-found"){
          changeEmail(account, emailChange);
        }
      }else{
        
      }
    } else{
      throw 'Failed to authenticate: ${e.toString()}';
    }
  }
}

Future<bool> changeEmail(User account, String newEmail) async{
  try{
    String? pass = await _encryptionService.readFromSecureStorage(key: 'password');
    if (account.email == null) throw 'Somehow your account doesnt have an email';
    if (pass == null) throw 'Failed to fetch auth details';

    String decryptedPass = _encryptionService.decrypt(pass);
    if (FirebaseAuth.instance.currentUser != null){
      FirebaseAuth.instance.signOut();
    }
    FirebaseAuth.instance.signInWithEmailAndPassword(email: newEmail, password: decryptedPass);
    _encryptionService.deleteFromSecureStorage(key: 'emailChange');
    return true;
  } catch (e){
    debugPrint('$e');
    return false;
  }
}

class ChangeEmailDialog extends StatefulWidget {
  const ChangeEmailDialog({super.key});

  @override
  ChangeEmailDialogState createState() => ChangeEmailDialogState();
}

class ChangeEmailDialogState extends State<ChangeEmailDialog> {
  final TextEditingController newEmail = TextEditingController();
  String? error;
  bool isLoading = false;
  
  @override
  void dispose() {
    newEmail.dispose();
    super.dispose();
  }

  Future<void> updateEmail() async {
    // First check email format
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(newEmail.text)) {
      setState(() {
        error = 'Invalid email format';
      });
      return;
    }

    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      // Get the current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          error = 'No user signed in';
          isLoading = false;
        });
        return;
      }
      await reAuthUser(user);
      await user.verifyBeforeUpdateEmail(newEmail.text);
      if (mounted) {
        Navigator.pop(context, newEmail.text);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'email-already-in-use':
            error = 'This email is already in use';
            break;
          case 'invalid-email':
            error = 'Invalid email format';
            break;
          case 'requires-recent-login':
            error = 'Please sign in again to change email';
            break;
          default:
            error = 'Error updating email';
        }
      });
    } catch (e) {
      setState(() {
        error = 'An unexpected error occurred';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change Email'),
      content: SizedBox(
        width: double.maxFinite,
        child: TextField(
          controller: newEmail,
          enabled: !isLoading,
          decoration: InputDecoration(
            labelText: 'New Email',
            labelStyle: const TextStyle(fontSize: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            errorText: error,
            suffixIcon: isLoading 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : null,
          ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [  
        ElevatedButton(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(Colors.black),
          ),
          onPressed: isLoading ? null : updateEmail,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60),
            child: isLoading 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Change'),
          ),
        ),
      ],
    );
  }
}

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  ChangePasswordDialogState createState() => ChangePasswordDialogState();
}

class ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final TextEditingController newPassword = TextEditingController();
  final TextEditingController confirmNewPassword = TextEditingController();
  Set error1Set = {};
  String? error1;
  Set error2Set = {};
  String? error2;

  @override
  void dispose() {
    newPassword.dispose();
    confirmNewPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change Password'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newPassword,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                labelStyle: const TextStyle(fontSize: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                errorText: error1,
              ),
              onChanged: (value) => setState((){
                if (value.length < 6){
                  error1Set.add('Password must be at least 6 characters');
                } else{
                  error1Set.remove('Password must be at least 6 characters');
                }
                if (!value.contains(RegExp(r'.*\d.*'))) {
                  error1Set.add('Password must contain a number');
                } else{
                  error1Set.remove('Password must contain a number');
                }
                if (error1Set.isNotEmpty){
                  error1 = error1Set.join('\n');
                } else{
                  error1 = null;
                }
              }),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: confirmNewPassword,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                labelStyle: const TextStyle(fontSize: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                errorText: error2,
              ),
              onChanged: (value) => setState((){
                if (value.length < 6){
                  error2Set.add('Password must be at least 6 characters');
                } else{
                  error2Set.remove('Password must be at least 6 characters');
                }
                if (!value.contains(RegExp(r'.*\d.*'))) {
                  error2Set.add('Password must contain a number');
                } else{
                  error2Set.remove('Password must contain a number');
                }
                if (error2Set.isNotEmpty){
                  error2 = error2Set.join('\n');
                } else{
                  error2 = null;
                }
              }),
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [  
        ElevatedButton(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(Colors.black),
          ),
          onPressed: () {
            setState(() {
              if (error1 != null || error2 != null) {
                return;
              }
              else if (newPassword.text.isEmpty) {
                error1Set.add('Password cannot be empty');
              } else if (confirmNewPassword.text.isEmpty) {
                error2Set.add('Password cannot be empty');
              } else if (newPassword.text != confirmNewPassword.text) {
                error1 = 'Passwords do not match';
                error2 = 'Passwords do not match';
              } else {
                error1 = null;
                Navigator.pop(context, newPassword.text); // Return the password or handle further.
              }
            });
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 60),
            child: Text('Change'),
          ),
        ),
      ],
    );
  }
}
