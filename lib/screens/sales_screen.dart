// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../language_data.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final supabase = Supabase.instance.client;

  // التحكم بالزبون
  int? _selectedCustomerId;
  final _customerController = TextEditingController();

  // التحكم بالمواد والبيع
  String _currency = 'IQD'; 
  final List<Map<String, dynamic>> _cartItems = [];
  double _paidAmount = 0;
  bool _isLoading = false;

  final _qtyController = TextEditingController();
  final _priceController = TextEditingController();
  dynamic _selectedProduct;

  List<dynamic> _customers = [];
  List<dynamic> _products = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final custData = await supabase.from('customers').select('id, name').order('name');
      final prodData = await supabase.from('products').select().gt('stock', 0).order('name');
      setState(() {
        _customers = custData;
        _products = prodData;
      });
    } catch (e) {
      debugPrint("Load Error: $e");
    }
  }

  void _addItemToCart() {
    if (_selectedProduct == null || _qtyController.text.isEmpty) return;
    int qty = int.parse(_qtyController.text);
    
    if (qty > _selectedProduct['stock']) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.get('out_of_stock'))));
      return;
    }

    setState(() {
      _cartItems.add({
        'id': _selectedProduct['id'],
        'name': _selectedProduct['name'],
        'quantity': qty,
        'unit_price': double.tryParse(_priceController.text) ?? 0.0,
      });
      _qtyController.clear();
      _priceController.clear();
      _selectedProduct = null;
    });
  }

  Future<void> _completeSale() async {
    String customerName = _customerController.text.trim();
    if (customerName.isEmpty || _cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("يرجى تحديد زبون وإضافة مواد")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      int? finalCustomerId = _selectedCustomerId;

      if (finalCustomerId == null) {
        final newCust = await supabase.from('customers').insert({
          'name': customerName,
          'balance_usd': 0,
          'balance_iqd': 0,
        }).select().single();
        finalCustomerId = newCust['id'];
      }

      double total = _cartItems.fold(0, (sum, item) => sum + (item['quantity'] * item['unit_price']));
      double remaining = total - _paidAmount;

      final sale = await supabase.from('sales').insert({
        'customer_id': finalCustomerId,
        'total_amount': total,
        'paid_amount': _paidAmount,
        'currency': _currency,
        'is_cash': remaining <= 0,
      }).select().single();

      for (var item in _cartItems) {
        await supabase.from('sales_items').insert({
          'sale_id': sale['id'],
          'product_name': item['name'],
          'quantity': item['quantity'],
          'unit_price': item['unit_price'],
          'currency': _currency,
        });

        await supabase.rpc('decrement_stock', params: {
          'row_id': item['id'],
          'count': item['quantity']
        });
      }

      if (remaining > 0) {
        String balanceField = _currency == 'USD' ? 'balance_usd' : 'balance_iqd';
        await supabase.rpc('update_customer_balance', params: {
          'cust_id': finalCustomerId,
          'amount': remaining,
          'field_name': balanceField
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تمت عملية البيع بنجاح")));
      Navigator.pop(context);
    } catch (e) {
      debugPrint("Sale Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("فشل الحفظ: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isRtl = AppStrings.currentLang != 'en';
    double totalBill = _cartItems.fold(0, (sum, item) => sum + (item['quantity'] * item['unit_price']));

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(title: Text(AppStrings.get('sell_now'))),
        body: _isLoading 
            ? const Center(child: CircularProgressIndicator()) 
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          _buildCustomerSearchField(), 
                          const SizedBox(height: 10),
                          _buildCurrencySelector(),
                          const Divider(),
                          _buildProductSelector(),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                    // سلة المواد تتمدد بشكل طبيعي وتدعم التمرير الآمن بداخل نظام الـ Slivers
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = _cartItems[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              title: Text(item['name']),
                              subtitle: Text("${item['quantity']} × ${item['unit_price']} $_currency"),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red), 
                                onPressed: () => setState(() => _cartItems.removeAt(index))
                              ),
                            ),
                          );
                        },
                        childCount: _cartItems.length,
                      ),
                    ),
                    // تجميع عناصر الدفع والزر السفلي ليدعموا الارتفاع التلقائي والهروب من الكيبورد
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const SizedBox(height: 15),
                          _buildPaymentSummary(totalBill),
                          const SizedBox(height: 10),
                          _buildConfirmButton(),
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

  Widget _buildCustomerSearchField() {
    return RawAutocomplete<Map<String, dynamic>>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text == '') {
          return const Iterable<Map<String, dynamic>>.empty();
        }
        return _customers.where((option) {
          return option['name']
              .toString()
              .toLowerCase()
              .contains(textEditingValue.text.toLowerCase());
        }).cast<Map<String, dynamic>>(); 
      },
      displayStringForOption: (option) => option['name'],
      onSelected: (selection) {
        setState(() {
          _selectedCustomerId = selection['id'];
          _customerController.text = selection['name'];
        });
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller..addListener(() { _customerController.text = controller.text; }),
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: AppStrings.get('customer_name'),
            hintText: AppStrings.get('search_or_add'),
            prefixIcon: const Icon(Icons.person_search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (val) => _selectedCustomerId = null, 
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topRight,
          child: Material(
            elevation: 4,
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              height: 200,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    title: Text(option['name']),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrencySelector() {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'IQD', label: Text("دينار عراقي")),
        ButtonSegment(value: 'USD', label: Text("دولار أمريكي")),
      ],
      selected: {_currency},
      onSelectionChanged: (val) => setState(() {
        _currency = val.first;
        _cartItems.clear();
      }),
    );
  }

  Widget _buildProductSelector() {
    return Column(
      children: [
        DropdownButtonFormField<dynamic>(
          value: _selectedProduct,
          decoration: InputDecoration(hintText: AppStrings.get('search_hint')),
          items: _products.map((p) => DropdownMenuItem(value: p, child: Text("${p['name']} (متوفر: ${p['stock']})"))).toList(),
          onChanged: (val) {
            setState(() {
              _selectedProduct = val;
              _priceController.text = (_currency == 'USD' ? val['price_usd'] : val['price_iqd']).toString();
            });
          },
        ),
        Row(
          children: [
            Expanded(child: TextField(controller: _qtyController, decoration: InputDecoration(labelText: AppStrings.get('units')), keyboardType: TextInputType.number)),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _priceController, 
                decoration: InputDecoration(labelText: AppStrings.get('sale_price')), 
                keyboardType: TextInputType.number,
              ),
            ),
            IconButton(icon: const Icon(Icons.add_shopping_cart, color: Colors.green, size: 35), onPressed: _addItemToCart),
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
            Text(AppStrings.get('total_bill')),
            Text("$total $_currency", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ]),
          TextField(
            decoration: InputDecoration(labelText: AppStrings.get('paid_amount')),
            keyboardType: TextInputType.number,
            onChanged: (v) => setState(() => _paidAmount = double.tryParse(v) ?? 0),
          ),
          const SizedBox(height: 5),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(AppStrings.get('remaining_amount')),
            Text("${total - _paidAmount} $_currency", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ]),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55), backgroundColor: Colors.indigo),
      onPressed: _completeSale,
      child: Text(AppStrings.get('confirm_sale'), style: const TextStyle(color: Colors.white, fontSize: 18)),
    );
  }
}