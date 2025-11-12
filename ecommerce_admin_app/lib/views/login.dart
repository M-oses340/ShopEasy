import 'dart:ui';
//import 'package:ecommerce_admin_app/controllers/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _localAuth = LocalAuthentication();
  final _storage = const FlutterSecureStorage();

  bool _isLoading = false;
  bool _authInProgress = false;
  bool _useBiometric = false;

  late AnimationController _blurController;
  late Animation<double> _blurAnimation;

  @override
  void initState() {
    super.initState();

    _blurController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _blurAnimation = Tween<double>(begin: 0.0, end: 6.0).animate(_blurController);

    // Load biometric preference and auto-login if enabled
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadBiometricPreference();
      if (_useBiometric) _tryBiometricLogin();
    });
  }

  Future<void> _loadBiometricPreference() async {
    final pref = await _storage.read(key: "use_biometric");
    if (!mounted) return;
    setState(() => _useBiometric = pref == "true");
  }

  Future<void> _saveBiometricPreference(bool value) async {
    await _storage.write(key: "use_biometric", value: value.toString());
    if (!mounted) return;
    setState(() => _useBiometric = value);
  }

  Future<void> _tryBiometricLogin() async {
    if (_authInProgress) return;
    _authInProgress = true;

    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      if (!canCheck || !isSupported) return;

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your admin account',
        biometricOnly: false, // works with local_auth ^3.0.0
      );

      if (authenticated && mounted) {
        await _storage.write(key: "logged_in", value: "true");
        Navigator.pushNamedAndRemoveUntil(context, "/home", (_) => false);
      }
    } catch (e) {
      debugPrint("Biometric login failed: $e");
    } finally {
      _authInProgress = false;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _blurController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    await _blurController.forward();

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final user = credential.user;
      if (user == null) throw Exception("User not found");

      if (!user.emailVerified) {
        await _blurController.reverse();
        setState(() => _isLoading = false);

        // 🔹 Ask user to verify email
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Email not verified"),
            content: const Text(
              "Please verify your email before logging in.\nWould you like to resend the verification link?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  await user.sendEmailVerification();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Verification email sent")),
                  );
                },
                child: const Text("Resend Email"),
              ),
            ],
          ),
        );
        return;
      }

      // ✅ Email verified, proceed
      await _storage.write(key: "logged_in", value: "true");
      await _blurController.reverse();
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login Successful")),
      );

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, "/home", (_) => false);
      }
    } on FirebaseAuthException catch (e) {
      await _blurController.reverse();
      setState(() => _isLoading = false);
      String message = "Login failed";
      if (e.code == 'user-not-found') message = "No user found for that email.";
      if (e.code == 'wrong-password') message = "Wrong password.";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red.shade400,
        ),
      );
    } catch (e) {
      await _blurController.reverse();
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e", style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  Future<void> _handleForgotPassword() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your email")),
      );
      return;
    }

    setState(() => _isLoading = true);
    await _blurController.forward();

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: _emailController.text);
      await _blurController.reverse();
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password reset link sent to your email")),
      );
    } catch (e) {
      await _blurController.reverse();
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e", style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 120),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Login",
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Access your admin account",
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 30),

                    // EMAIL
                    TextFormField(
                      controller: _emailController,
                      enabled: !_isLoading,
                      validator: (v) {
                        if (v == null || v.isEmpty) return "Email cannot be empty";
                        final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                        if (!regex.hasMatch(v)) return "Enter a valid email";
                        return null;
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "Email",
                      ),
                    ),
                    const SizedBox(height: 15),

                    // PASSWORD
                    TextFormField(
                      controller: _passwordController,
                      enabled: !_isLoading,
                      obscureText: true,
                      validator: (v) => v != null && v.length >= 8
                          ? null
                          : "Password must be at least 8 characters",
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "Password",
                      ),
                    ),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isLoading ? null : _handleForgotPassword,
                        child: const Text("Forgot Password?"),
                      ),
                    ),

                    // BIOMETRIC TOGGLE
                    Row(
                      children: [
                        Switch(
                          value: _useBiometric,
                          onChanged: _isLoading
                              ? null
                              : (v) async {
                            final canCheck = await _localAuth.canCheckBiometrics;
                            if (!canCheck) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Biometric not available")),
                              );
                              return;
                            }
                            await _saveBiometricPreference(v);
                          },
                        ),
                        const Expanded(
                            child: Text("Use biometric / PIN for next login")),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // LOGIN BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          height: 25,
                          width: 25,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : const Text("Login", style: TextStyle(fontSize: 16)),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don’t have an account?"),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.pushNamed(context, "/signup"),
                          child: const Text("Sign Up"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // LOADING OVERLAY
          AnimatedBuilder(
            animation: _blurAnimation,
            builder: (context, _) => AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isLoading ? 1.0 : 0.0,
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: _blurAnimation.value,
                  sigmaY: _blurAnimation.value,
                ),
                child: Container(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.4),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
