import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final _storage = const FlutterSecureStorage();
  User? _user;
  bool _isSending = false;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;

    if (_user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
    }
  }

  Future<void> _sendVerificationEmail() async {
    if (_user == null) return;

    setState(() => _isSending = true);
    try {
      await _user!.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Verification email sent")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red.shade400,
        ),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _refreshVerificationStatus() async {
    if (_user == null) return;

    setState(() => _isRefreshing = true);
    await _user!.reload();
    _user = FirebaseAuth.instance.currentUser;

    if (_user!.emailVerified) {
      // Email verified → mark as logged in
      await _storage.write(key: "logged_in", value: "true");

      // Optionally enable biometric login automatically
      final useBiometric = await _storage.read(key: "use_biometric");
      if (useBiometric != "true") {
        await _storage.write(key: "use_biometric", value: "true");
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email verified! Logging in...")),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email not verified yet")),
      );
    }
    setState(() => _isRefreshing = false);
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    await _storage.delete(key: "logged_in");
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Scaffold(body: SizedBox.shrink());
    }

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Verify Email"),
        backgroundColor: theme.colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: "Logout",
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.email, size: 80, color: theme.colorScheme.primary),
            const SizedBox(height: 20),
            Text(
              "A verification email has been sent to:",
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              _user!.email ?? "No email",
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: _isSending
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : const Icon(Icons.send),
              label: const Text("Resend Verification Email"),
              onPressed: _isSending ? null : _sendVerificationEmail,
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              icon: _isRefreshing
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : const Icon(Icons.refresh),
              label: const Text("Refresh Status"),
              onPressed: _isRefreshing ? null : _refreshVerificationStatus,
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            ),
            const SizedBox(height: 30),
            TextButton(
              onPressed: _logout,
              child: const Text("Back to Login"),
            ),
          ],
        ),
      ),
    );
  }
}
