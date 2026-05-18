// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../language_data.dart';

class SubscriptionService {
  static final _supabase = Supabase.instance.client;

  // فحص اشتراك المستخدم الحالي وإظهار التنبيهات أو الحجب المناسب
  static Future<bool> checkUserSubscription(BuildContext context) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    try {
      // جلب السجل المالي والصلاحية السنوية من جدول التحكم
      final profile = await _supabase
          .from('user_profiles')
          .select('is_premium, subscription_ends_at')
          .eq('id', user.id)
          .single();

      bool isPremium = profile['is_premium'] ?? false;
      if (isPremium) return true; // تفعيل دائم مدى الحياة بدون قيود زمنية

      if (profile['subscription_ends_at'] != null) {
        DateTime expiryDate = DateTime.parse(profile['subscription_ends_at']);
        DateTime now = DateTime.now();

        // 1. حالة انتهاء الصلاحية بالكامل (حجب الواجهات والمطالبة بالتسديد)
        if (now.isAfter(expiryDate)) {
          _showExpiryDialog(context, isExpired: true, daysLeft: 0);
          return false;
        }

        // 2. حالة اقتراب انتهاء السنة (تنبيه مرن متبقي أقل من 10 أيام)
        int daysLeft = expiryDate.difference(now).inDays;
        if (daysLeft <= 10 && daysLeft >= 0) {
          _showExpiryDialog(context, isExpired: false, daysLeft: daysLeft);
        }
      }

      return true;
    } catch (e) {
      debugPrint("Subscription Check Error: $e");
      return false;
    }
  }

  static void _showExpiryDialog(BuildContext context, {required bool isExpired, required int daysLeft}) {
    bool isKu = AppStrings.currentLang == 'ku';
    bool isEn = AppStrings.currentLang == 'en';

    showDialog(
      context: context,
      barrierDismissible: !isExpired, // يمنع إغلاق التنبيه نهائياً إذا انتهى الاشتراك
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(isExpired ? Icons.lock : Icons.warning_amber_rounded, color: isExpired ? Colors.red : Colors.orange, size: 28),
            const SizedBox(width: 8),
            Text(
              isExpired 
                  ? (isKu ? "ماوەی بەکارهێنان بەسەرچوو" : isEn ? "Subscription Expired" : "انتهت الصلاحية السنوية")
                  : (isKu ? "ئاگاداری کۆتایی هاتنی قۆناغ" : isEn ? "Subscription Warning" : "تنبيه قرب انتهاء الاشتراك"),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          isExpired
              ? (isKu 
                  ? "ماوەی بەکارهێنانی ساڵانەی ئەپڵیکەیشنەکەت بەسەرچووە. تکایە بۆ نوێکردنەوە پەیوەندی بکە بە گەشەپێدەری سیستەمی Code X."
                  : isEn
                      ? "Your annual subscription has expired. Please contact Code X developer to renew your license."
                      : "لقد انتهى اشتراكك السنوي في التطبيق. يرجى التواصل مع مطور نظام Code X لتجديد الترخيص وتسديد الرسوم.")
              : (isKu
                  ? "تەنها $daysLeft ڕۆژ ماوە بۆ کۆتایی هاتنی بەکارهێنانی ئەپڵیکەیشنەکەت. تکایە کاتی خۆی نوێی بکەرەوە."
                  : isEn
                      ? "Only $daysLeft days left for your subscription to expire. Please renew on time."
                      : "متبقي $daysLeft أيام فقط على انتهاء اشتراكك السنوي في البرنامج. يرجى التجديد في الوقت المحدد لتفادي توقف الخدمة."),
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: isExpired ? Colors.red : Colors.orange),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(isKu ? "داخستن" : isEn ? "Close" : "إغلاق"),
          )
        ],
      ),
    );
  }
}