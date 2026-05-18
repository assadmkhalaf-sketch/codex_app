// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../language_data.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;

  // أصول (ما نملكه)
  double totalStockUSD = 0;
  double totalStockIQD = 0;
  double customerDebtsUSD = 0;
  double customerDebtsIQD = 0;

  // التزامات ونفقات (ما ندفعه)
  double supplierDebtsUSD = 0;
  double supplierDebtsIQD = 0;
  double totalExpensesUSD = 0;
  double totalExpensesIQD = 0;

  // المبيعات والأرباح (القسم الجديد لـ Code X)
  double totalSalesUSD = 0;
  double totalSalesIQD = 0;
  double netProfitUSD = 0;
  double netProfitIQD = 0;

  @override
  void initState() {
    super.initState();
    _calculateStatistics();
  }

  Future<void> _calculateStatistics() async {
    setState(() => _isLoading = true);
    try {
      // 1. حساب قيمة المخزن الحالية
      final products = await supabase.from('products').select('stock, price_usd, price_iqd');
      totalStockUSD = 0; totalStockIQD = 0;
      for (var p in products) {
        totalStockUSD += (p['stock'] ?? 0) * (p['price_usd'] ?? 0.0);
        totalStockIQD += (p['stock'] ?? 0) * (p['price_iqd'] ?? 0.0);
      }

      // 2. حساب ديون الزبائن (لنا في السوق)
      final customers = await supabase.from('customers').select('balance_usd, balance_iqd');
      customerDebtsUSD = 0; customerDebtsIQD = 0;
      for (var c in customers) {
        customerDebtsUSD += (c['balance_usd'] ?? 0.0);
        customerDebtsIQD += (c['balance_iqd'] ?? 0.0);
      }

      // 3. حساب ديون الموردين (علينا للشركات)
      final suppliers = await supabase.from('suppliers').select('balance_usd, balance_iqd');
      supplierDebtsUSD = 0; supplierDebtsIQD = 0;
      for (var s in suppliers) {
        supplierDebtsUSD += (s['balance_usd'] ?? 0.0);
        supplierDebtsIQD += (s['balance_iqd'] ?? 0.0);
      }

      // 4. حساب إجمالي النفقات والمصاريف التشغيلية
      final expenses = await supabase.from('expenses').select('amount, currency');
      totalExpensesUSD = 0; totalExpensesIQD = 0;
      for (var e in expenses) {
        if (e['currency'] == 'USD') {
          totalExpensesUSD += (e['amount'] ?? 0.0);
        } else {
          totalExpensesIQD += (e['amount'] ?? 0.0);
        }
      }

      // 5. جلب إجمالي المبيعات لحساب الأرباح بدقة
      final sales = await supabase.from('sales').select('total_amount, currency');
      totalSalesUSD = 0; totalSalesIQD = 0;
      for (var s in sales) {
        if (s['currency'] == 'USD') {
          totalSalesUSD += (s['total_amount'] ?? 0.0);
        } else {
          totalSalesIQD += (s['total_amount'] ?? 0.0);
        }
      }

      // 6. معادلة صافي الأرباح: المبيعات الكلية مطروحاً منها المصاريف الكلية
      netProfitUSD = totalSalesUSD - totalExpensesUSD;
      netProfitIQD = totalSalesIQD - totalExpensesIQD;

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint("Stats Error: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isRtl = AppStrings.currentLang != 'en';

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(AppStrings.get('financial_summary')),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _calculateStatistics)],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // كروت الأصول (ممتلكات النظام)
                    _statCard(AppStrings.get('inventory'), totalStockUSD, totalStockIQD, Colors.blue),
                    const SizedBox(height: 12),
                    _statCard(AppStrings.get('customer_debts'), customerDebtsUSD, customerDebtsIQD, Colors.teal),
                    
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(thickness: 1),
                    ),

                    // كروت الالتزامات والنفقات
                    _statCard(AppStrings.get('supplier_debts'), supplierDebtsUSD, supplierDebtsIQD, Colors.orange),
                    const SizedBox(height: 12),
                    _statCard(AppStrings.get('expenses'), totalExpensesUSD, totalExpensesIQD, Colors.red),
                    
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(thickness: 1),
                    ),

                    // كرت الأرباح الصافية المطور (ديناميكي الألوان)
                    _profitCard(),

                    const SizedBox(height: 25),
                    
                    // الصافي المالي النهائي للشركة
                    _netWorthSection(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _statCard(String title, double usd, double iqd, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        border: Border(right: BorderSide(color: color, width: 5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black54)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _amountDisplay("\$ ${usd.toStringAsFixed(2)}", "USD", color),
              _amountDisplay("${iqd.toStringAsFixed(0)} IQD", "IQD", color),
            ],
          )
        ],
      ),
    );
  }

  // كرت الأرباح الديناميكي: يتحول للأخضر في الربح وللأحمر في الخسارة تبعا لحسابات الأسواق في الموبايل
  Widget _profitCard() {
    bool isLossUSD = netProfitUSD < 0;
    bool isLossIQD = netProfitIQD < 0;
    
    Color cardColor = (isLossUSD && isLossIQD) ? Colors.red.shade700 : Colors.green.shade700;
    String titleText = AppStrings.currentLang == 'ku' ? "قازانجی پاکتاوکراو" : AppStrings.currentLang == 'en' ? "Net Profit" : "صافي الأرباح والفوائد";

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        border: Border(right: BorderSide(color: cardColor, width: 6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(titleText, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: cardColor)),
              Icon(Icons.trending_up, color: cardColor),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _amountDisplay(
                "\$ ${netProfitUSD.toStringAsFixed(2)}", 
                "USD", 
                isLossUSD ? Colors.red : Colors.green.shade700
              ),
              _amountDisplay(
                "${netProfitIQD.toStringAsFixed(0)} IQD", 
                "IQD", 
                isLossIQD ? Colors.red : Colors.green.shade700
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _amountDisplay(String val, String label, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(val, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _netWorthSection() {
    double netUSD = (totalStockUSD + customerDebtsUSD) - (supplierDebtsUSD + totalExpensesUSD);
    double netIQD = (totalStockIQD + customerDebtsIQD) - (supplierDebtsIQD + totalExpensesIQD);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.indigo, Colors.blueAccent]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Text(AppStrings.get('net_worth'), style: const TextStyle(color: Color.fromARGB(255, 241, 242, 243), fontSize: 15)),
          const SizedBox(height: 8),
          Text("\$ ${netUSD.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
          Text("${netIQD.toStringAsFixed(0)} IQD", style: const TextStyle(color: Colors.white70, fontSize: 17)),
        ],
      ),
    );
  }
}