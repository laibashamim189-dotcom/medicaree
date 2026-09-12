import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart';
import 'signup_screen.dart';
import 'admin_login_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.enableNetwork();

      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get()
          .timeout(const Duration(seconds: 15));

      if (userDoc.exists) {
        String role = userDoc.get('role');
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => RoleWrapper(role: role)),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile data missing. Please complete your registration.")),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SignupScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showForgotPasswordDialog() {
    final TextEditingController resetEmailController =
        TextEditingController(text: _emailController.text.trim());
    bool isSending = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text(
              "Reset Password",
              style: TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.bold, fontSize: 22),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Enter your email address to receive a password reset link.", style: TextStyle(color: Colors.black54, fontSize: 14)),
                const SizedBox(height: 20),
                TextFormField(
                  controller: resetEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: "Email Address",
                    prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF1565C0)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF1565C0))),
                    filled: true, fillColor: Colors.white,
                  ),
                ),
              ],
            ),
            actions: [
              if (isSending) const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
              else Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontSize: 16))),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
                      onPressed: () async {
                        String email = resetEmailController.text.trim();
                        if (email.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter your email")));
                          return;
                        }
                        setDialogState(() => isSending = true);
                        try {
                          await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password reset link sent!")));
                          }
                        } catch (e) {
                          setDialogState(() => isSending = false);
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                        }
                      },
                      child: const Text("Send Link", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color brandBlue = Color(0xFF1565C0);
    const Color darkBlueText = Color(0xFF1A233A);

    return Scaffold(
      backgroundColor: brandBlue,
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.white))
        : SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 70),
                GestureDetector(
                  onTap: () {
                    if (kIsWeb) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Admin access is only available on Web."),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
                  child: Column(
                    children: [
                      Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle), child: const SizedBox(width: 60, height: 50, child: FittedBox(fit: BoxFit.contain, child: Icon(Icons.medical_services, color: Colors.white)))),
                      const SizedBox(height: 10),
                      const Text("Medicare", style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.white)),
                      const Text("Smart Healthcare Reminder", style: TextStyle(fontSize: 14, color: Colors.white70)),
                    ],
                  ),
                ),
                const SizedBox(height: 35),
                Container(
                  width: double.infinity, margin: const EdgeInsets.symmetric(horizontal: 25), padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 8))]),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("Welcome Back", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: darkBlueText)),
                        const SizedBox(height: 25),
                        TextFormField(
                          controller: _emailController, keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(hintText: "Email Address", prefixIcon: const Icon(Icons.email_outlined, color: brandBlue), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none), filled: true, fillColor: const Color(0xFFF3F6F9), contentPadding: const EdgeInsets.symmetric(vertical: 15)),
                          validator: (value) => (value == null || value.isEmpty) ? 'Enter your email' : null,
                        ),
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: _passwordController, obscureText: _obscurePassword,
                          decoration: InputDecoration(hintText: "Password", prefixIcon: const Icon(Icons.lock_outline, color: brandBlue), suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: brandBlue), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none), filled: true, fillColor: const Color(0xFFF3F6F9), contentPadding: const EdgeInsets.symmetric(vertical: 15)),
                          validator: (value) => (value == null || value.isEmpty) ? 'Enter your password' : null,
                        ),
                        const SizedBox(height: 5),
                        Align(alignment: Alignment.centerRight, child: TextButton(onPressed: _showForgotPasswordDialog, child: const Text("Forgot Password?", style: TextStyle(color: brandBlue, fontWeight: FontWeight.w600)))),
                        const SizedBox(height: 20),
                        ElevatedButton(style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 58), backgroundColor: brandBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), elevation: 0), onPressed: _login, child: const Text("LOGIN", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 35),
                TextButton(
                  onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const SignupScreen())),
                  child: RichText(text: const TextSpan(text: "Don't have an account? ", style: TextStyle(color: Colors.white70, fontSize: 15), children: [TextSpan(text: "Sign Up", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))])),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
    );
  }
}
