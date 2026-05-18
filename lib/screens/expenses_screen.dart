// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../language_data.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final supabase = Supabase.instance.client;
  final _reasonController = TextEditingController();
  final _amountController = TextEditingController();
  String _currency = 'IQD';
  bool _isLoading = false;
  List<dynamic> _expenses = [];

  @override
  void initState() {
    super.initState();
    _fetchExpenses();
  }

  Future<void> _fetchExpenses() async {
    setState(() => _isLoading = true);
    try {
      final data = await supabase.from('expenses').select().order('created_at', ascending: false);
      setState(() {
        _expenses = data;
      });
    } catch (e) {
      debugPrint("Fetch Expenses Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveExpense() async {
    if (_reasonController.text.isEmpty || _amountController.text.isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      await supabase.from('expenses').insert({
        'reason': _reasonController.text,
        'amount': double.tryParse(_amountController.text) ?? 0.0,
        'currency': _currency,
      });
      
      _reasonController.clear();
      _amountController.clear();
      
      if (!mounted) return;
      Navigator.pop(context); // إغلاق الدايلوج بأمان
      _fetchExpenses(); // إعادة تحديث القائمة
    } catch (e) {
      debugPrint("Save Expense Error: $e");
      setState(() => _isLoading = false);
    }
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        // استخدام StatefulBuilder لتحديث حالة الـ Dropdown داخل الدايلوج نفسه
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(AppStrings.get('add_expense')),
            content: SingleChildScrollView(
              // التغليف السحري لحماية الحقول والهروب من لوحة المفاتيح
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _reasonController, 
                    decoration: InputDecoration(labelText: AppStrings.get('expense_reason'))
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _amountController, 
                    decoration: InputDecoration(labelText: AppStrings.get('expense_amount')), 
                    keyboardType: TextInputType.number
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: _currency,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: ['IQD', 'USD'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) {
                      // تحديث الحالة بداخل الدايلوج والشاشة الرئيسية معاً لضمان المزامنة
                      setDialogState(() => _currency = v!);
                      setState(() => _currency = v!);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _reasonController.clear();
                  _amountController.clear();
                  Navigator.pop(context);
                }, 
                child: Text(AppStrings.get('cancel'))
              ),
              ElevatedButton(
                onPressed: _saveExpense, 
                child: Text(AppStrings.get('save'))
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isRtl = AppStrings.currentLang != 'en';
    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(title: Text(AppStrings.get('expenses'))),
        body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _expenses.length,
              itemBuilder: (context, index) {
                final exp = _expenses[index];
                return ListTile(
                  leading: const Icon(Icons.outbox, color: Colors.red),
                  title: Text(exp['reason']),
                  subtitle: Text(exp['created_at'].toString().split('T')[0]),
                  trailing: Text(
                    "${exp['amount']} ${exp['currency']}", 
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)
                  ),
                );
              },
            ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddDialog,
          backgroundColor: Colors.redAccent,
          child: const Icon(Icons.add, color: Colors.white), // تم تعديل الأيقونة لتناسب إدخال مصروف جديد بدلاً من عربة تسوق المبيعات
        ),
      ),
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}