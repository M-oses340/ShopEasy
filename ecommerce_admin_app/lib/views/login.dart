import 'dart:convert';
import 'dart:ui';
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
  bool _obscurePassword = true;

  late final AnimationController _blurController;
  late final Animation<double> _blurAnimation;

  @override
  void initState() {
    super.initState();

    _blurController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _blurAnimation = Tween<double>(begin: 0.0, end: 5.0).animate(_blurController);

    WidgetsBinding.instance.addPostFrameCallback((_) => _checkBiometricAutoLogin());
  }

  Future<void> _checkBiometricAutoLogin() async {
    final loggedIn = await _storage.read(key: "logged_in");
    final biometricRegistered = await _storage.read(key: "biometric_registered");

    final canCheck = await _localAuth.canCheckBiometrics;
    final supported = await _localAuth.isDeviceSupported();

    if (canCheck && supported && loggedIn == "true" && biometricRegistered == "true") {
      await Future.delayed(const Duration(milliseconds: 300));
      _tryBiometricLogin();
    }
  }

  Future<void> _tryBiometricLogin() async {
    if (_authInProgress) return;
    _authInProgress = true;

    setState(() => _isLoading = true);
    await _blurController.forward();

    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final supported = await _localAuth.isDeviceSupported();
      final biometrics = await _localAuth.getAvailableBiometrics();

      if (!canCheck || !supported || biometrics.isEmpty) {
        debugPrint("No biometrics available.");
        return;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your admin account',
        biometricOnly: false,
      );

      if (!authenticated) {
        debugPrint("Biometric authentication failed or canceled.");
        return;
      }

      final email = await _storage.read(key: "user_email");
      final encodedPassword = await _storage.read(key: "user_password");

      if (email == null || encodedPassword == null) {
        debugPrint("No stored credentials for biometric login.");
        return;
      }

      // ✅ Handle both encoded and plain text passwords
      late String password;
      try {
        password = utf8.decode(base64Decode(encodedPassword));
      } catch (_) {
        // fallback if previously stored as plain text
        password = encodedPassword;
      }

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }

      await _storage.write(key: "logged_in", value: "true");

      if (!mounted) return;
      await _blurController.reverse();
      setState(() => _isLoading = false);

      Navigator.pushNamedAndRemoveUntil(context, "/home", (_) => false);
    } catch (e) {
      debugPrint("Biometric login error: $e");
      if (mounted) {
        await _blurController.reverse();
        setState(() => _isLoading = false);
      }
    } finally {
      _authInProgress = false;
    }
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
        await user.sendEmailVerification();
        if (!mounted) return;
        await _blurController.reverse();
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please verify your email before logging in.")),
        );
        return;
      }

      // ✅ Encode password for biometric storage
      final encodedPassword = base64Encode(utf8.encode(password));
      await _storage.write(key: "user_email", value: email);
      await _storage.write(key: "user_password", value: encodedPassword);
      await _storage.write(key: "biometric_registered", value: "true");
      await _storage.write(key: "logged_in", value: "true");

      if (!mounted) return;
      await _blurController.reverse();
      setState(() => _isLoading = false);

      Navigator.pushNamedAndRemoveUntil(context, "/home", (_) => false);
    } on FirebaseAuthException catch (e) {
      await _blurController.reverse();
      setState(() => _isLoading = false);

      String message;
      switch (e.code) {
        case 'user-not-found':
          message = "No user found for that email.";
          break;
        case 'wrong-password':
          message = "Incorrect password.";
          break;
        default:
          message = "Login failed. Please try again.";
      }

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
      if (!mounted) return;
      await _blurController.reverse();
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password reset link sent")),
      );
    } catch (e) {
      if (!mounted) return;
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
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _blurController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 120),
            physics: const BouncingScrollPhysics(),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Login",
                      style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("Access your admin account",
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 30),

                  TextFormField(
                    controller: _emailController,
                    enabled: !_isLoading,
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Email cannot be empty";
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) return "Enter a valid email";
                      return null;
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Email",
                    ),
                  ),
                  const SizedBox(height: 15),

                  TextFormField(
                    controller: _passwordController,
                    enabled: !_isLoading,
                    obscureText: _obscurePassword,
                    validator: (v) =>
                    v != null && v.length >= 8 ? null : "Password must be at least 8 characters",
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: "Password",
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                        onPressed: _isLoading
                            ? null
                            : () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading ? null : _handleForgotPassword,
                      child: const Text("Forgot Password?"),
                    ),
                  ),

                  const SizedBox(height: 20),
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
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                          : const Text("Login", style: TextStyle(fontSize: 16)),
                    ),
                  ),

                  const SizedBox(height: 15),

                  Center(
                    child: IconButton(
                      icon: const Icon(Icons.fingerprint, size: 32),
                      onPressed: _isLoading ? null : _tryBiometricLogin,
                      tooltip: "Login with Biometrics",
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Blur overlay when loading
          AnimatedBuilder(
            animation: _blurAnimation,
            builder: (context, _) => _isLoading
                ? BackdropFilter(
              filter: ImageFilter.blur(
                  sigmaX: _blurAnimation.value, sigmaY: _blurAnimation.value),
              child: Container(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.35)
                    : Colors.white.withValues(alpha: 0.35),

                alignment: Alignment.center,
                child: const CircularProgressIndicator(),
              ),
            )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
