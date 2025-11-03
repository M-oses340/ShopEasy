import 'package:ecommerce_admin_app/controllers/auth_service.dart';
import 'package:flutter/material.dart';

class SingupPage extends StatefulWidget {
  const SingupPage({super.key});

  @override
  State<SingupPage> createState() => _SingupPageState();
}

class _SingupPageState extends State<SingupPage> {
  final formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final result = await AuthService().createAccountWithEmail(email, password);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result == "Account Created") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account created successfully!")),
      );
      Navigator.restorablePushNamedAndRemoveUntil(
        context,
        "/home",
            (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final inputDecoration = InputDecoration(
      border: const OutlineInputBorder(),
      labelStyle: TextStyle(color: Colors.grey.shade700),
    );

    return Scaffold(
      body: SingleChildScrollView(
        child: AbsorbPointer(
          absorbing: _isLoading, // disable input when loading
          child: Form(
            key: formKey,
            child: Column(
              children: [
                const SizedBox(height: 120),
                SizedBox(
                  width: MediaQuery.of(context).size.width * .9,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Sign Up",
                        style: TextStyle(
                            fontSize: 40, fontWeight: FontWeight.w700),
                      ),
                      const Text("Create a new account and get started"),
                      const SizedBox(height: 20),
                      TextFormField(
                        validator: (value) =>
                        value!.isEmpty ? "Email cannot be empty." : null,
                        controller: _emailController,
                        decoration:
                        inputDecoration.copyWith(labelText: "Email"),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        validator: (value) => value!.length < 8
                            ? "Password should have at least 8 characters."
                            : null,
                        controller: _passwordController,
                        obscureText: true,
                        decoration:
                        inputDecoration.copyWith(labelText: "Password"),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 60,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSignup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            textStyle: const TextStyle(fontSize: 16),
                          ),
                          child: _isLoading
                              ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text("Creating account..."),
                            ],
                          )
                              : const Text("Sign Up"),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account?"),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                        Navigator.pop(context);
                      },
                      child: const Text("Login"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
