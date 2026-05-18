// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; 
import 'language_data.dart';
import 'screens/dashboard_screen.dart'; 
import 'screens/auth_screen.dart'; // استيراد واجهة الدخول الجديدة لنظام الحسابات والاشتراك

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://ecnydhsgvtlahgdnyziv.supabase.co', 
    anonKey: 'sb_publishable_x_ALOh1kmKM5mlM0akNzHA__kIjZ32Y',
  );
  runApp(const CodeXApp());
}

class CodeXApp extends StatefulWidget {
  const CodeXApp({super.key});

  static void setLocale(BuildContext context) {
    _CodeXAppState? state = context.findAncestorStateOfType<_CodeXAppState>();
    // ignore: invalid_use_of_protected_member
    state?.setState(() {});
  }

  @override
  State<CodeXApp> createState() => _CodeXAppState();
}

class _CodeXAppState extends State<CodeXApp> {
  @override
  Widget build(BuildContext context) {
    // فحص سحابي سريع لحالة تسجيل الدخول فور إقلاع النظام
    final session = Supabase.instance.client.auth.currentSession;

    return MaterialApp(
      key: ValueKey(AppStrings.currentLang), // يضمن تحديث التطبيق بالكامل عند تغيير اللغة
      debugShowCheckedModeBanner: false,
      title: 'Code X',
      locale: Locale(AppStrings.currentLang),
      supportedLocales: const [
        Locale('ar'),
        Locale('ku'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // الحل الخاص بالكردية لضمان الاتجاه الصحيح للغات الـ RTL
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale?.languageCode == 'ku') {
          return const Locale('ar'); 
        }
        return locale;
      },
      // التوجيه الذكي: إذا كان مسجل دخوله يذهب للوحة التحكم مباشرة، وإلا لشاشة تسجيل الدخول
      home: session != null ? const DashboardScreen() : const AuthScreen(),
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/home': (context) => const DashboardScreen(),
      },
    );
  }
}