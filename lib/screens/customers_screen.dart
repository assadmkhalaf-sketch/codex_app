import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../language_data.dart'; // تأكد من مسار القاموس

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final supabase = Supabase.instance.client;
  
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _balanceUsdController = TextEditingController();
  final _balanceIqdController = TextEditingController();

  bool _isLoading = true;
  List<dynamic> _customers = [];

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  Future<void> _fetchCustomers() async {
    setState(() => _isLoading = true);
    try {
      final data = await supabase.from('customers').select().order('name');
      setState(() {
        _customers = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveCustomer() async {
    if (_nameController.text.isEmpty) return;
    await supabase.from('customers').insert({
      'name': _nameController.text,
      'phone': _phoneController.text,
      'balance_usd': double.tryParse(_balanceUsdController.text) ?? 0.0,
      'balance_iqd': double.tryParse(_balanceIqdController.text) ?? 0.0,
    });
    // ignore: use_build_context_synchronously
    Navigator.pop(context);
    _nameController.clear(); _phoneController.clear();
    _balanceUsdController.clear(); _balanceIqdController.clear();
    _fetchCustomers();
  }

  void _showAddCustomerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.get('customer_name')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _nameController, decoration: InputDecoration(labelText: AppStrings.get('customer_name'))),
              TextField(controller: _phoneController, decoration: InputDecoration(labelText: AppStrings.get('phone')), keyboardType: TextInputType.phone),
              const Divider(height: 30),
              const Text("ديون سابقة بذمة الزبون", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
              TextField(controller: _balanceUsdController, decoration: const InputDecoration(labelText: "دين سابق (\$)", suffixText: "USD"), keyboardType: TextInputType.number),
              TextField(controller: _balanceIqdController, decoration: const InputDecoration(labelText: "دين سابق (د.ع)", suffixText: "IQD"), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppStrings.get('cancel'))),
          ElevatedButton(onPressed: _saveCustomer, child: Text(AppStrings.get('save'))),
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
        appBar: AppBar(title: Text(AppStrings.get('customer_name'))),
        body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _customers.length,
              itemBuilder: (context, index) {
                final c = _customers[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(c['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Row(
                      children: [
                        _debtChip("\$ ${c['balance_usd']}", Colors.purple.shade700),
                        const SizedBox(width: 10),
                        _debtChip("${c['balance_iqd']} IQD", Colors.deepPurple.shade900),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  ),
                );
              },
            ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.purple,
          onPressed: _showAddCustomerDialog,
          child: const Icon(Icons.person_add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _debtChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color)),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}