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
  bool _useBiometric = false;
  bool _obscurePassword = true;

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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadBiometricPreference();

      final loggedIn = await _storage.read(key: "logged_in");
      final biometricRegistered = await _storage.read(key: "biometric_registered");

      if (_useBiometric && loggedIn == "true" && biometricRegistered == "true") {
        await Future.delayed(const Duration(milliseconds: 300));
        await _tryBiometricLogin();
      }
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

    setState(() => _isLoading = true);
    await _blurController.forward();

    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      final available = await _localAuth.getAvailableBiometrics();

      if (!canCheck || !isSupported || available.isEmpty) {
        debugPrint("Biometric not available or supported.");
        return;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your admin account',
        biometricOnly: false, // Allows PIN fallback
      );

      if (!authenticated) {
        debugPrint("Biometric auth canceled or failed.");
        return;
      }

      // ✅ Retrieve stored credentials quickly
      final email = await _storage.read(key: "user_email");
      final password = await _storage.read(key: "user_password");

      if (email == null || password == null) {
        debugPrint("No valid user found for biometric login.");
        return;
      }

      // ✅ If already logged in, skip Firebase delay
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }

      await _storage.write(key: "logged_in", value: "true");

      // ✅ Instantly transition to home
      if (!mounted) return;
      await _blurController.reverse();
      setState(() => _isLoading = false);

      Navigator.pushNamedAndRemoveUntil(context, "/home", (_) => false);
    } catch (e) {
      debugPrint("Biometric login failed: $e");
      await _blurController.reverse();
      setState(() => _isLoading = false);
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

      // First-time login: check email verification
      if (!user.emailVerified) {
        await user.sendEmailVerification();
        await _blurController.reverse();
        setState(() => _isLoading = false);
        Navigator.pushReplacementNamed(context, '/verify-email');
        return;
      }

      // Store credentials for future biometric login if user opts in
      if (_useBiometric) {
        await _storage.write(key: "user_email", value: email);
        await _storage.write(key: "user_password", value: password); // optional
        await _storage.write(key: "biometric_registered", value: "true");
      }

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
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 120),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Login", style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text("Access your admin account", style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 30),
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
                    TextFormField(
                      controller: _passwordController,
                      enabled: !_isLoading,
                      obscureText: _obscurePassword,
                      validator: (v) => v != null && v.length >= 8 ? null : "Password must be at least 8 characters",
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: "Password",
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                          onPressed: _isLoading ? null : () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(onPressed: _isLoading ? null : _handleForgotPassword, child: const Text("Forgot Password?")),
                    ),
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
                        const Expanded(child: Text("Use biometric / PIN for next login")),
                      ],
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
                  ],
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _blurAnimation,
            builder: (context, _) => AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isLoading ? 1.0 : 0.0,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: _blurAnimation.value, sigmaY: _blurAnimation.value),
                child: Container(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.4),

                  child: _isLoading ? const Center(child: CircularProgressIndicator()) : const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
