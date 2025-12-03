import 'dart:async';
import 'package:wordini/Pages/Account/sign_in.dart';
import 'package:wordini/encryption_controller.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wordini/widgets.dart';

final EncryptionService _encryptionService = EncryptionService.instance;

class AccountPage extends StatefulWidget {
  final User accountDetails;
  const AccountPage({super.key, required this.accountDetails});
  
  @override
  AccountPageState createState() => AccountPageState();
}

class AccountPageState extends State<AccountPage> {
  late User account;
  final EncryptionService encryption = EncryptionService.instance;
  
  @override
  void initState() {
    account = widget.accountDetails;
    super.initState();
  }

  @override
  Widget build(BuildContext context) { 
    final isGoogleAccount = account.providerData.first.providerId == 'google.com';
    
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 14, 14, 14),
      appBar: AppBar(
        title: const Text('Account Settings'),
        backgroundColor: Colors.black,
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            _buildProfileHeader(),
            
            const SizedBox(height: 20),
            
            // Account Information Section
            _buildSection(
              title: 'Account Information',
              children: [
                _buildInfoTile(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: account.email ?? 'No email',
                  trailing: !isGoogleAccount 
                    ? IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: _handleEmailChange,
                      )
                    : null,
                ),
                if (!isGoogleAccount)
                  _buildInfoTile(
                    icon: Icons.lock_outline,
                    label: 'Password',
                    value: '••••••••••',
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: _handlePasswordChange,
                    ),
                  ),
                _buildInfoTile(
                  icon: Icons.shield_outlined,
                  label: 'Sign-in method',
                  value: isGoogleAccount ? 'Google' : 'Email & Password',
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Actions Section
            _buildSection(
              title: 'Actions',
              children: [
                _buildActionTile(
                  icon: Icons.logout,
                  label: 'Sign Out',
                  color: Colors.orange.shade700,
                  onTap: _handleSignOut,
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Danger Zone
            _buildSection(
              title: 'Danger Zone',
              children: [
                _buildActionTile(
                  icon: Icons.delete_forever_outlined,
                  label: 'Delete Account',
                  color: Colors.red,
                  onTap: _handleDeleteAccount,
                ),
              ],
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            foregroundImage: account.photoURL != null 
              ? NetworkImage(account.photoURL!) 
              : null,
            backgroundColor: Colors.blue[700],
            child: Text(
              (account.email?.substring(0, 1).toUpperCase() ?? 'U'),
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            account.displayName ?? account.email?.split('@')[0] ?? 'User',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (account.email != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                account.email!,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Colors.blue[300],
        size: 24,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 12,
        ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: trailing,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: color,
        size: 24,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  Future<void> _handleEmailChange() async {
    try {
      String? newEmail = await showDialog(
        context: context,
        builder: (BuildContext context) => const ChangeEmailDialog(),
      );  

      if (newEmail != null) {
        _encryptionService.writeToSecureStorage(key: 'emailChange', value: newEmail);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Verification email sent. Please check your email to complete the change.'),
              backgroundColor: Colors.green[700],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          errorSnackBar(e),
        );
      }
    }
  }

  Future<void> _handlePasswordChange() async {
    try {
      String? newPass = await showDialog(
        context: context,
        builder: (BuildContext context) => const ChangePasswordDialog(),
      );

      if (newPass != null) {
        newPass = newPass.trim();
        if (newPass == '') throw 'Password cannot be empty';
        await reAuthUser(account);
        await account.updatePassword(newPass);
        _encryptionService.writeToSecureStorage(
          key: 'password', 
          value: encryption.encrypt(newPass)
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Password updated successfully'),
              backgroundColor: Colors.green[700],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          errorSnackBar(e),
        );
      }
    }
  }

  Future<void> _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      _encryptionService.clearAllSecureStorage();
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _handleDeleteAccount() async {
    final bool res = await showDialog(
      context: context, 
      builder: (BuildContext context) {
        String email = account.email ?? 'Error getting email';
        int lenEmail = email.length;
        email = email.substring(0, (lenEmail/3-(lenEmail/12).round()).round()) + 
                ('*' * (lenEmail - (lenEmail/3*2).round())) + 
                email.substring((lenEmail/3*2-(lenEmail/12)).round(), lenEmail);
        TextEditingController controller = TextEditingController();
        
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red[700]),
              const SizedBox(width: 8),
              const Text('Delete Account'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This action cannot be undone. All your data will be permanently deleted.',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              Text(
                'Please type your email to confirm:',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Enter your email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (controller.text == account.email) {
                  Navigator.of(context).pop(true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Email does not match'),
                      backgroundColor: Colors.red[700],
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red[700],
              ),
              child: const Text('Delete Account'),
            ),
          ],
        );
      }
    );
    
    if (res) {
      LoadingOverlay loadingOverlay = LoadingOverlay();
      if (context.mounted) loadingOverlay.showLoadingOverlay(context);
      try {
        await reAuthUser(account);
        await FirebaseAuth.instance.currentUser?.delete();
        await FirebaseAuth.instance.signOut();
        _encryptionService.clearAllSecureStorage();
        loadingOverlay.removeLoadingOverlay();
        if (context.mounted) Navigator.pop(context);
      } catch (e) {
        loadingOverlay.removeLoadingOverlay();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            errorSnackBar(e),
          );
        }
      }
    }
  }
}

// Keep your existing reAuthUser and changeEmail functions...
Future<void> reAuthUser(User account, {String? email}) async {
  String? emailChange = await _encryptionService.readFromSecureStorage(key: 'emailChange');
  try {
    switch (account.providerData.first.providerId) {
      case 'google.com':
        String? storedToken = await _encryptionService.readFromSecureStorage(key: 'authIdToken');
        if (account.email == null) throw 'Somehow your account doesnt have an email';
        if (storedToken == null) throw 'Failed to fetch auth details';

        String authIdToken = _encryptionService.decrypt(storedToken);
        AuthCredential credential = GoogleAuthProvider.credential(idToken: authIdToken);
        await account.reauthenticateWithCredential(credential);
      case 'password':
        String? oldPass = await _encryptionService.readFromSecureStorage(key: 'password');
        if (account.email == null) throw 'Somehow your account doesnt have an email';
        if (oldPass == null) throw 'Failed to fetch auth details';

        String decryptedPass = _encryptionService.decrypt(oldPass);
        AuthCredential credential = EmailAuthProvider.credential(
          email: email ?? account.email ?? '', 
          password: decryptedPass
        );
        await account.reauthenticateWithCredential(credential);
      default:
        throw 'Unsupported provider for re-authentication.';
    }
  } catch (e) {
    if (e is FirebaseAuthException) {
      if (email == null && emailChange != null) {
        if (e.code == "user-not-found") {
          changeEmail(account, emailChange);
        }
      }
    } else {
      throw 'Failed to authenticate: ${e.toString()}';
    }
  }
}

Future<bool> changeEmail(User account, String newEmail) async {
  try {
    String? pass = await _encryptionService.readFromSecureStorage(key: 'password');
    if (account.email == null) throw 'Somehow your account doesnt have an email';
    if (pass == null) throw 'Failed to fetch auth details';

    String decryptedPass = _encryptionService.decrypt(pass);
    if (FirebaseAuth.instance.currentUser != null) {
      FirebaseAuth.instance.signOut();
    }
    FirebaseAuth.instance.signInWithEmailAndPassword(email: newEmail, password: decryptedPass);
    _encryptionService.deleteFromSecureStorage(key: 'emailChange');
    return true;
  } catch (e) {
    debugPrint('$e');
    return false;
  }
}

// Your existing dialog classes remain the same...
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Change Email'),
      content: SizedBox(
        width: double.maxFinite,
        child: TextField(
          controller: newEmail,
          enabled: !isLoading,
          decoration: InputDecoration(
            labelText: 'New Email',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            errorText: error,
            suffixIcon: isLoading 
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : null,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: isLoading ? null : updateEmail,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                errorText: error1,
              ),
              onChanged: (value) => setState(() {
                if (value.length < 6) {
                  error1Set.add('Password must be at least 6 characters');
                } else {
                  error1Set.remove('Password must be at least 6 characters');
                }
                if (!value.contains(RegExp(r'.*\d.*'))) {
                  error1Set.add('Password must contain a number');
                } else {
                  error1Set.remove('Password must contain a number');
                }
                error1 = error1Set.isNotEmpty ? error1Set.join('\n') : null;
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmNewPassword,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                errorText: error2,
              ),
              onChanged: (value) => setState(() {
                if (value.length < 6) {
                  error2Set.add('Password must be at least 6 characters');
                } else {
                  error2Set.remove('Password must be at least 6 characters');
                }
                if (!value.contains(RegExp(r'.*\d.*'))) {
                  error2Set.add('Password must contain a number');
                } else {
                  error2Set.remove('Password must contain a number');
                }
                error2 = error2Set.isNotEmpty ? error2Set.join('\n') : null;
              }),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            setState(() {
              if (error1 != null || error2 != null) {
                return;
              } else if (newPassword.text.isEmpty) {
                error1Set.add('Password cannot be empty');
              } else if (confirmNewPassword.text.isEmpty) {
                error2Set.add('Password cannot be empty');
              } else if (newPassword.text != confirmNewPassword.text) {
                error1 = 'Passwords do not match';
                error2 = 'Passwords do not match';
              } else {
                Navigator.pop(context, newPassword.text);
              }
            });
          },
          child: const Text('Change'),
        ),
      ],
    );
  }
}