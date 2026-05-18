// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../language_data.dart'; 
import '../main.dart'; // استيراد الـ setLocale لتحديث التطبيق بالكامل
import '../screens/subscription_service.dart'; // استيراد سيرفيس فحص الاشتراك السنوي
import 'inventory_screen.dart';
import 'suppliers_screen.dart';
import 'customers_screen.dart';
import 'purchase_screen.dart';
import 'sales_screen.dart';
import 'customer_debts_screen.dart';
import 'sales_list_screen.dart';
import 'statistics_screen.dart'; 
import 'expenses_screen.dart'; 
import 'payments_screen.dart'; 
import 'supplier_debts_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    // فحص اشتراك التاجر السنوي فور فتح لوحة التحكم الرئيسية للتطبيق لمنع المتجاوزين
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SubscriptionService.checkUserSubscription(context);
    });
  }
  
  // دالة تغيير اللغة وتحديث الواجهة فوراً داخل الداشبورد وكامل أجزاء النظام
  void _updateLanguage(String langCode) {
    setState(() {
      AppStrings.currentLang = langCode;
    });
    CodeXApp.setLocale(context); // إجبار التطبيق بالكامل على إعادة البناء بالاتجاه الجديد
  }

  // دالة تسجيل الخروج السحابي الآمن لمنع تداخل الحسابات والمحلات
  Future<void> _handleLogout() async {
    try {
      await _supabase.auth.signOut();
      Navigator.pushReplacementNamed(context, '/auth');
    } catch (e) {
      debugPrint("Logout Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isRtl = AppStrings.currentLang != 'en';
    bool isKu = AppStrings.currentLang == 'ku';
    bool isEn = AppStrings.currentLang == 'en';

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text("Code X - Smart Solutions", style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: isKu ? "چوونە دەرەوە" : isEn ? "Logout" : "تسجيل الخروج السحابي",
            onPressed: _handleLogout,
          ),
          actions: [
            _languagePicker(), // زر اختيار اللغة المحدث
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(), // الهيدر يقرأ الترجمة المحدثة تلقائياً
              const SizedBox(height: 25),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  children: [
                    _menuCard(AppStrings.get('inventory'), Icons.inventory_2, Colors.blue, const InventoryScreen()),
                    _menuCard(AppStrings.get('sales'), Icons.point_of_sale, Colors.green, const SalesScreen()),
                    _menuCard(AppStrings.get('supplier_name'), Icons.local_shipping, Colors.orange, const SuppliersScreen()),
                    _menuCard(AppStrings.get('customer_name'), Icons.people_alt, Colors.purple, const CustomersScreen()),
                    _menuCard(AppStrings.get('sales_list'), Icons.receipt_long, Colors.redAccent, const SalesListScreen()),
                    _menuCard(AppStrings.get('purchase_invoice'), Icons.add_shopping_cart, Colors.teal, const PurchaseScreen()),
                    _menuCard(AppStrings.get('customer_debts'), Icons.money_off, Colors.red, const CustomerStatementScreen()),
                    _menuCard(AppStrings.get('supplier_debts'), Icons.account_balance_wallet, Colors.indigo, const SupplierStatementScreen()),
                    _menuCard(AppStrings.get('expenses'), Icons.money_off_rounded, Colors.redAccent, const ExpensesScreen()),
                    _menuCard(AppStrings.get('financial_summary'), Icons.analytics_outlined, Colors.indigo, const StatisticsScreen()),
                    _menuCard(AppStrings.get('payments_management'), Icons.payments_outlined, Colors.teal, const PaymentsScreen()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // هيدر الترحيب المحدث
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(colors: [Colors.indigo, Colors.blueAccent]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.get('dashboard'),
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.get('quick_actions'),
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // تصميم البطاقات
  Widget _menuCard(String title, IconData icon, Color color, Widget screen) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => screen)),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        color: Colors.white,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, size: 35, color: color),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // قائمة اختيار اللغة التي تطلق الـ setState والـ setLocale للمزامنة الشاملة
  Widget _languagePicker() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.language, color: Colors.white),
      onSelected: _updateLanguage,
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'ar', child: Text("العربية")),
        const PopupMenuItem(value: 'ku', child: Text("کوردی")),
        const PopupMenuItem(value: 'en', child: Text("English")),
      ],
    );
  }
}