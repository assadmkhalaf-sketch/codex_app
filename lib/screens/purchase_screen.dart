// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../language_data.dart';

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  final supabase = Supabase.instance.client;

  int? _selectedSupplierId;
  String _currency = 'USD'; 
  double _paidAmount = 0; 
  final List<Map<String, dynamic>> _invoiceItems = [];
  bool _isLoading = false;

  final _itemNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _paidController = TextEditingController();

  List<dynamic> _suppliers = [];

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    try {
      final data = await supabase.from('suppliers').select('id, name').order('name');
      setState(() => _suppliers = data);
    } catch (e) {
      debugPrint("Load Suppliers Error: $e");
    }
  }

  void _addItemToInvoice() {
    if (_itemNameController.text.isEmpty || _priceController.text.isEmpty) return;
    
    setState(() {
      _invoiceItems.add({
        'product_name': _itemNameController.text,
        'quantity': int.tryParse(_quantityController.text) ?? 1,
        'unit_price': double.tryParse(_priceController.text) ?? 0.0,
      });
      _itemNameController.clear();
      _quantityController.clear();
      _priceController.clear();
    });
  }

  Future<void> _saveInvoice() async {
    if (_selectedSupplierId == null || _invoiceItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.get('select_person')))
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      double total = _invoiceItems.fold(0, (sum, item) => sum + (item['quantity'] * item['unit_price']));
      double remaining = total - _paidAmount;

      final purchase = await supabase.from('purchases').insert({
        'supplier_id': _selectedSupplierId,
        'total_amount': total,
        'paid_amount': _paidAmount,
        'currency': _currency,
        'is_cash': remaining <= 0,
      }).select().single();

      final int purchaseId = purchase['id'];
      String selectedSupplierName = _suppliers.firstWhere((s) => s['id'] == _selectedSupplierId)['name'];

      for (var item in _invoiceItems) {
        await supabase.from('purchase_items').insert({
          'purchase_id': purchaseId,
          'product_name': item['product_name'],
          'quantity': item['quantity'],
          'unit_price': item['unit_price'],
          'currency': _currency,
        });

        final existing = await supabase.from('products').select().eq('name', item['product_name']).maybeSingle();
        
        if (existing != null) {
          await supabase.from('products').update({
            'stock': (existing['stock'] as int) + (item['quantity'] as int),
            'last_supplier': selectedSupplierName,
            (_currency == 'USD' ? 'price_usd' : 'price_iqd'): item['unit_price'],
          }).eq('id', existing['id']);
        } else {
          await supabase.from('products').insert({
            'name': item['product_name'],
            'stock': item['quantity'],
            'last_supplier': selectedSupplierName,
            'price_usd': _currency == 'USD' ? item['unit_price'] : 0.0,
            'price_iqd': _currency == 'IQD' ? item['unit_price'] : 0.0,
          });
        }
      }

      if (remaining > 0) {
        final supplier = await supabase.from('suppliers').select().eq('id', _selectedSupplierId!).single();
        String balanceField = _currency == 'USD' ? 'balance_usd' : 'balance_iqd';
        double currentBalance = (supplier[balanceField] as num).toDouble();

        await supabase.from('suppliers').update({
          balanceField: currentBalance + remaining,
        }).eq('id', _selectedSupplierId!);
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.get('success_update'))));
      Navigator.pop(context);
    } catch (e) {
      debugPrint("Save Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ في حفظ الفاتورة: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isRtl = AppStrings.currentLang != 'en';
    double totalInvoice = _invoiceItems.fold(0, (sum, item) => sum + (item['quantity'] * item['unit_price']));

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(title: Text(AppStrings.get('purchase_invoice'))),
        body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: CustomScrollView(
                slivers: [
                  // المكونات العلوية وحقول النص تهرب بذكاء عند ظهور الكيبورد
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        _buildHeader(),
                        const Divider(),
                        _buildItemInput(),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                  // قائمة المواد المشتراة تتمدد وتسحب بشكل طبيعي دون تعارض ارتفاعات
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = _invoiceItems[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text(item['product_name']),
                            subtitle: Text("${item['quantity']} × ${item['unit_price']} $_currency"),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle, color: Colors.red), 
                              onPressed: () => setState(() => _invoiceItems.removeAt(index))
                            ),
                          ),
                        );
                      },
                      childCount: _invoiceItems.length,
                    ),
                  ),
                  // الملخص المالي وزر الحفظ النهائي يثبتان في الأسفل ويدعمان الارتفاع الديناميكي
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const SizedBox(height: 15),
                        _buildPaymentSummary(totalInvoice),
                        const SizedBox(height: 10),
                        _buildSaveButton(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildHeader() {
    // جلب ترجمة العملة لتتوافق مع الكردية والعربية والانجليزية بمرونة
    String labelCurrency = AppStrings.currentLang == 'ku' ? "دراو" : AppStrings.currentLang == 'en' ? "Currency" : "العملة";

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<int>(
            value: _selectedSupplierId,
            decoration: InputDecoration(
              labelText: AppStrings.get('supplier_name'),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: _suppliers.map((s) => DropdownMenuItem<int>(value: s['id'], child: Text(s['name']))).toList(),
            onChanged: (val) => setState(() => _selectedSupplierId = val),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _currency,
            decoration: InputDecoration(
              labelText: labelCurrency,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: const [
              DropdownMenuItem(value: 'USD', child: Text("USD")),
              DropdownMenuItem(value: 'IQD', child: Text("IQD")),
            ],
            onChanged: (val) => setState(() {
              _currency = val!;
              _invoiceItems.clear();
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildItemInput() {
    return Column(
      children: [
        TextField(
          controller: _itemNameController, 
          decoration: InputDecoration(
            labelText: AppStrings.get('name'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _quantityController, 
                decoration: InputDecoration(
                  labelText: AppStrings.get('units'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ), 
                keyboardType: TextInputType.number
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _priceController, 
                decoration: InputDecoration(
                  labelText: AppStrings.get('price'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ), 
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 5),
            IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.teal, size: 45), 
              onPressed: _addItemToInvoice
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentSummary(double total) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.blueGrey.shade50, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(AppStrings.get('total_bill'), style: const TextStyle(fontWeight: FontWeight.bold)),
            Text("$total $_currency", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16)),
          ]),
          TextField(
            controller: _paidController,
            decoration: InputDecoration(labelText: AppStrings.get('paid_amount')),
            keyboardType: TextInputType.number,
            onChanged: (v) => setState(() => _paidAmount = double.tryParse(v) ?? 0),
          ),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(AppStrings.get('remaining_amount')),
            Text(
              "${total - _paidAmount} $_currency", 
              style: TextStyle(color: (total - _paidAmount) > 0 ? Colors.red : Colors.green, fontWeight: FontWeight.bold)
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 55), 
        backgroundColor: Colors.teal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: _saveInvoice,
      child: Text(AppStrings.get('save'), style: const TextStyle(fontSize: 18, color: Colors.white)),
    );
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _paidController.dispose();
    super.dispose();
  }
}