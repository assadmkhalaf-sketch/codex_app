// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../language_data.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final supabase = Supabase.instance.client;
  
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _balanceUsdController = TextEditingController();
  final _balanceIqdController = TextEditingController();

  bool _isLoading = true;
  List<dynamic> _suppliers = [];

  @override
  void initState() {
    super.initState();
    _fetchSuppliers();
  }

  Future<void> _fetchSuppliers() async {
    setState(() => _isLoading = true);
    try {
      final data = await supabase.from('suppliers').select().order('name');
      setState(() {
        _suppliers = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSupplier() async {
    if (_nameController.text.isEmpty) return;

    try {
      await supabase.from('suppliers').insert({
        'name': _nameController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'balance_usd': double.tryParse(_balanceUsdController.text) ?? 0.0,
        'balance_iqd': double.tryParse(_balanceIqdController.text) ?? 0.0,
      });
      
      _clearControllers();
      Navigator.pop(context);
      _fetchSuppliers();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.get('success_update'))));
    } catch (e) {
      debugPrint("Save Error: $e");
    }
  }

  void _clearControllers() {
    _nameController.clear();
    _phoneController.clear();
    _addressController.clear();
    _balanceUsdController.clear();
    _balanceIqdController.clear();
  }

  void _showAddSupplierDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.get('add_supplier')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _nameController, decoration: InputDecoration(labelText: AppStrings.get('supplier_name'))),
              TextField(controller: _phoneController, decoration: InputDecoration(labelText: AppStrings.get('phone')), keyboardType: TextInputType.phone),
              TextField(controller: _addressController, decoration: InputDecoration(labelText: AppStrings.get('address'))),
              const Divider(height: 30),
              Text(AppStrings.get('previous_debts'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              TextField(controller: _balanceUsdController, decoration: const InputDecoration(labelText: "USD", suffixText: "USD"), keyboardType: TextInputType.number),
              TextField(controller: _balanceIqdController, decoration: const InputDecoration(labelText: "IQD", suffixText: "IQD"), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppStrings.get('cancel'))),
          ElevatedButton(onPressed: _saveSupplier, child: Text(AppStrings.get('save'))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isRtl = AppStrings.currentLang != 'en';

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(title: Text(AppStrings.get('supplier_name'))),
        body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _suppliers.length,
              itemBuilder: (context, index) {
                final s = _suppliers[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  elevation: 3,
                  child: ListTile(
                    title: Text(s['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (s['phone'] != null && s['phone'] != "") Text("📞 ${s['phone']}"),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            _balanceChip("\$ ${s['balance_usd']}", Colors.red.shade700),
                            const SizedBox(width: 10),
                            _balanceChip("${s['balance_iqd']} IQD", Colors.orange.shade800),
                          ],
                        ),
                      ],
                    ),
                    trailing: Icon(isRtl ? Icons.arrow_back_ios : Icons.arrow_forward_ios, size: 16),
                  ),
                );
              },
            ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddSupplierDialog,
          child: const Icon(Icons.person_add),
        ),
      ),
    );
  }

  Widget _balanceChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color)),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}