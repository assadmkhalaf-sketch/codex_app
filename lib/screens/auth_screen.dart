// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../language_data.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _supabase = Supabase.instance.client;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isSignUp = false; // التبديل بين تسجيل الدخول وإنشاء حساب جديد

  Future<void> _handleAuth() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      if (_isSignUp) {
        // إنشاء حساب تاجر جديد في نظام Code X
        await _supabase.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.currentLang == 'ku' 
                ? "تۆمارکردن سەرکەوتوو بوو! ئەگەر پێویست بوو ئیمەیڵەکەت پشتڕاست بکەرەوە." 
                : AppStrings.currentLang == 'en'
                    ? "Sign up successful! Please verify your email if required."
                    : "تم إنشاء الحساب بنجاح! يرجى تأكيد البريد الإلكتروني إن لزم الأمر."), 
            backgroundColor: Colors.green
          ),
        );
      } else {
        // تسجيل دخول تاجر مسجل مسبقاً
        await _supabase.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        // التوجيه للشاشة الرئيسية للتطبيق بعد النجاح
        Navigator.pushReplacementNamed(context, '/home'); 
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isKu = AppStrings.currentLang == 'ku';
    bool isEn = AppStrings.currentLang == 'en';

    return Directionality(
      textDirection: isEn ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_shopping_cart, size: 80, color: Colors.indigo.shade800),
                const SizedBox(height: 10),
                Text("Code X Multi-User", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo.shade900)),
                const SizedBox(height: 30),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: isKu ? "ئیمەیڵ (Email)" : isEn ? "Email Address" : "البريد الإلكتروني للتاجر",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: isKu ? "وشەی نهێنی (Password)" : isEn ? "Password" : "كلمة المرور",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 25),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52),
                          backgroundColor: Colors.indigo.shade800,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _handleAuth,
                        child: Text(
                          _isSignUp 
                              ? (isKu ? "دروستکردنی حساب" : isEn ? "Create Account" : "إنشاء حساب تاجر جديد")
                              : (isKu ? "چوونە ژوورەوە" : isEn ? "Login" : "تسجيل الدخول"),
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                const SizedBox(height: 15),
                TextButton(
                  onPressed: () => setState(() => _isSignUp = !_isSignUp),
                  child: Text(
                    _isSignUp
                        ? (isKu ? "حسابت هەیە؟ بچۆ ژوورەوە" : isEn ? "Have an account? Login" : "تمتلك حساباً بالفعل؟ سجل دخولك")
                        : (isKu ? "حسابت نییە؟ لێرە دروستی بکە" : isEn ? "Don't have an account? Sign Up" : "ليس لديك حساب؟ أنشئ حسابك الآن للمحل"),
                    style: TextStyle(color: Colors.indigo.shade700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}