// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../language_data.dart';
import 'invoice_detail_screen.dart';

class CustomerStatementScreen extends StatefulWidget {
  const CustomerStatementScreen({super.key});

  @override
  State<CustomerStatementScreen> createState() => _CustomerStatementScreenState();
}

class _CustomerStatementScreenState extends State<CustomerStatementScreen> {
  final supabase = Supabase.instance.client;
  bool _isLoading = false;
  List<dynamic> _allCustomers = [];
  List<dynamic> _filteredCustomers = [];
  final _searchController = TextEditingController();

  Map<String, dynamic>? _selectedCustomer;
  String _selectedCurrency = 'IQD';
  List<Map<String, dynamic>> _customerInvoices = [];

  double _totalAmount = 0;
  double _totalPaid = 0;
  double _totalRemaining = 0;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    try {
      final data = await supabase.from('customers').select('id, name, balance_iqd, balance_usd').order('name');
      setState(() {
        _allCustomers = data;
        _filteredCustomers = data;
      });
    } catch (e) {
      debugPrint("Load Customers Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterCustomers(String query) {
    setState(() {
      _filteredCustomers = _allCustomers
          .where((c) => c['name'].toString().toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> _deleteCustomer(int customerId, String customerName) async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        bool isKu = AppStrings.currentLang == 'ku';
        bool isEn = AppStrings.currentLang == 'en';
        
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              const SizedBox(width: 8),
              Text(
                AppStrings.get('delete_title'), 
                style: const TextStyle(fontFamily: 'NotoSansArabic', fontWeight: FontWeight.bold)
              ),
            ],
          ),
          content: Text(
            isKu 
                ? "دڵنیای لە سڕینەوەی کڕیار ($customerName)؟\nگشت فاکتۆرەکان، ماددەکان و بڕە پارەکان دەسڕدرێنەوە و ناتوانیت بیگەڕێنیتەوە."
                : isEn
                    ? "Are you sure you want to permanently delete customer ($customerName)?\nAll invoices, items, and payments associated will be deleted permanently."
                    : "هل أنت متأكد من حذف الزبون ($customerName)؟\nسيتم حذف كافة الفواتير، المواد، والمدفوعات المرتبطة به نهائياً ولا يمكن التراجع عن هذا الإجراء.",
            style: const TextStyle(fontFamily: 'NotoSansArabic', fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                isKu ? "پاشگەزبوونەوە" : isEn ? "Cancel" : "إلغاء", 
                style: const TextStyle(fontFamily: 'NotoSansArabic', color: Colors.grey)
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                isKu ? "بەڵێ، گشت بسڕەوە" : isEn ? "Yes, Delete All" : "نعم، احذف الكل", 
                style: const TextStyle(fontFamily: 'NotoSansArabic', color: Colors.white)
              ),
            ),
          ],
        );
      },
    ) ?? false;

    if (!confirmDelete) return;

    setState(() => _isLoading = true);

    try {
      final salesData = await supabase.from('sales').select('id').eq('customer_id', customerId);
      List<int> saleIds = salesData.map((s) => int.parse(s['id'].toString())).toList();

      if (saleIds.isNotEmpty) {
        for (var id in saleIds) {
          await supabase.from('sales_items').delete().eq('sale_id', id);
        }
      }

      await supabase.from('sales').delete().eq('customer_id', customerId);
      await supabase.from('payments').delete().eq('person_id', customerId.toString()).eq('person_type', 'customer');
      await supabase.from('customers').delete().eq('id', customerId);

      bool isKu = AppStrings.currentLang == 'ku';
      bool isEn = AppStrings.currentLang == 'en';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isKu 
                ? "کڕیار ($customerName) و گشت زانیارییەکانی بە سەرکەوتوویی سڕدرانەوە!" 
                : isEn 
                    ? "Customer ($customerName) and all associated data deleted successfully!" 
                    : "تم حذف الزبون ($customerName) وكافة بياناته بنجاح!"
          ), 
          backgroundColor: Colors.green
        ),
      );

      setState(() {
        _selectedCustomer = null;
        _customerInvoices.clear();
      });
      _loadCustomers();

    } catch (e) {
      debugPrint("Delete Customer Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchCustomerInvoices() async {
    if (_selectedCustomer == null) return;
    setState(() => _isLoading = true);

    try {
      final data = await supabase
          .from('sales')
          .select('id, total_amount, paid_amount, created_at')
          .eq('customer_id', _selectedCustomer!['id'])
          .eq('currency', _selectedCurrency)
          .order('created_at', ascending: false);

      double tempTotalInvoicesAmount = 0;
      double tempTotalInitialPaid = 0; 
      List<Map<String, dynamic>> tempInvoices = [];

      for (var s in data) {
        double total = (s['total_amount'] is num) ? (s['total_amount'] as num).toDouble() : 0.0;
        double initialPaid = (s['paid_amount'] is num) ? (s['paid_amount'] as num).toDouble() : 0.0;
        
        tempTotalInvoicesAmount += total;
        tempTotalInitialPaid += initialPaid; 

        tempInvoices.add({
          'id': s['id'],
          'total_amount': total,
          'paid_amount': initialPaid,
          'date': s['created_at'].toString().split('T')[0],
        });
      }

      final paymentsData = await supabase
          .from('payments')
          .select('amount')
          .eq('person_id', _selectedCustomer!['id'].toString())
          .eq('person_type', 'customer')
          .eq('currency', _selectedCurrency);

      double tempTotalPayments = 0;
      for (var p in paymentsData) {
        tempTotalPayments += (p['amount'] is num) ? (p['amount'] as num).toDouble() : 0.0;
      }

      setState(() {
        _customerInvoices = tempInvoices;
        _totalAmount = tempTotalInvoicesAmount;
        _totalPaid = tempTotalInitialPaid + tempTotalPayments;
        _totalRemaining = _totalAmount - _totalPaid;
      });
    } catch (e) {
      debugPrint("Fetch Customer Invoices Error: $e");
    } finally {
      setState(() => _isLoading = false);
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
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(_selectedCustomer == null 
              ? (AppStrings.get('customers')) 
              : _selectedCustomer!['name']),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          leading: _selectedCustomer != null
              ? IconButton(
                  icon: Icon(isRtl ? Icons.arrow_back : Icons.arrow_forward),
                  onPressed: () {
                    setState(() {
                      _selectedCustomer = null;
                      _customerInvoices.clear();
                    });
                  },
                )
              : null,
          actions: _selectedCustomer != null
              ? [
                  IconButton(
                    icon: const Icon(Icons.delete_forever, color: Colors.white, size: 28),
                    tooltip: isKu ? "سڕینەوەی یەکجاری کڕیار" : isEn ? "Permanently Delete Customer" : "حذف الزبون نهائياً",
                    onPressed: () => _deleteCustomer(_selectedCustomer!['id'], _selectedCustomer!['name']),
                  ),
                  const SizedBox(width: 8),
                ]
              : null,
        ),
        body: _isLoading && _allCustomers.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _selectedCustomer == null
                ? _buildCustomersListStage()
                : _buildCustomerInvoicesStage(),
      ),
    );
  }

  Widget _buildCustomersListStage() {
    bool isKu = AppStrings.currentLang == 'ku';
    bool isEn = AppStrings.currentLang == 'en';

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: _filterCustomers,
            decoration: InputDecoration(
              labelText: AppStrings.get('search_hint'),
              prefixIcon: const Icon(Icons.search, color: Colors.indigo),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _filteredCustomers.isEmpty
                    ? Center(child: Text(isKu ? "هیچ کڕیارێک نەدۆزرایەوە" : isEn ? "No customers found" : "لا يوجد زبائن مطابقين للبحث"))
                    : ListView.builder(
                        itemCount: _filteredCustomers.length,
                        itemBuilder: (context, index) {
                          final c = _filteredCustomers[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            elevation: 2,
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Colors.indigo,
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                              title: Text(c['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              subtitle: Text("IQD: ${c['balance_iqd'] ?? 0} | USD: \$${c['balance_usd'] ?? 0}"),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                    onPressed: () => _deleteCustomer(c['id'], c['name']),
                                  ),
                                  Icon(AppStrings.currentLang == 'en' ? Icons.chevron_right : Icons.chevron_left, color: Colors.indigo),
                                ],
                              ),
                              onTap: () {
                                setState(() {
                                  _selectedCustomer = c;
                                });
                                _fetchCustomerInvoices();
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInvoicesStage() {
    bool isKu = AppStrings.currentLang == 'ku';
    bool isEn = AppStrings.currentLang == 'en';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: _selectedCurrency,
                  decoration: InputDecoration(
                    labelText: isKu ? "دراوی حساب" : isEn ? "Statement Currency" : "عملة الحساب المعروض",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: [
                    DropdownMenuItem(value: 'IQD', child: Text(isKu ? "دیناری عێراقی (IQD)" : isEn ? "Iraqi Dinar (IQD)" : "دينار عراقي (IQD)")),
                    DropdownMenuItem(value: 'USD', child: Text(isKu ? "دۆلاری ئەمریکی (USD)" : isEn ? "US Dollar (USD)" : "دولار أمريكي (USD)")),
                  ],
                  onChanged: (v) {
                    setState(() => _selectedCurrency = v!);
                    _fetchCustomerInvoices();
                  },
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
                    border: Border(right: BorderSide(color: Colors.red.shade700, width: 5)),
                  ),
                  child: Column(
                    children: [
                      _summaryRow(AppStrings.get('customer_total_invoices'), _totalAmount),
                      const SizedBox(height: 6),
                      _summaryRow(AppStrings.get('total_paid_amount'), _totalPaid, isGreen: true),
                      const Divider(height: 20),
                      _summaryRow(AppStrings.get('remaining_debt_balance'), _totalRemaining, isRed: true, isBold: true),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
              ],
            ),
          ),
          _isLoading
              ? const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(30.0), child: CircularProgressIndicator())))
              : _customerInvoices.isEmpty
                  ? SliverToBoxAdapter(child: Center(child: Padding(padding: const EdgeInsets.all(40.0), child: Text(AppStrings.get('no_invoices'), style: const TextStyle(color: Colors.grey)))))
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final inv = _customerInvoices[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Colors.indigo,
                                child: Icon(Icons.description, color: Colors.white),
                              ),
                              title: Text("${AppStrings.get('sales_invoice_title')} #${inv['id']}"),
                              subtitle: Text(inv['date']),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text("${inv['total_amount']} $_selectedCurrency", style: const TextStyle(fontWeight: FontWeight.bold)),
                                      if (inv['paid_amount'] > 0)
                                        Text(
                                          "${AppStrings.get('down_payment_prefix')}: ${inv['paid_amount']}", 
                                          style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w500)
                                        ),
                                    ],
                                  ),
                                  const SizedBox(width: 5),
                                  Icon(AppStrings.currentLang == 'en' ? Icons.chevron_right : Icons.chevron_left, color: Colors.grey)
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => InvoiceDetailScreen(
                                      invoiceId: inv['id'],
                                      customerId: _selectedCustomer!['id'],
                                      customerName: _selectedCustomer!['name'],
                                      currency: _selectedCurrency,
                                      totalInvoiceAmount: inv['total_amount'],
                                      invoiceDate: inv['date'],
                                    ),
                                  ),
                                ).then((_) => _fetchCustomerInvoices());
                              },
                            ),
                          );
                        },
                        childCount: _customerInvoices.length,
                      ),
                    ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double val, {bool isGreen = false, bool isRed = false, bool isBold = false}) {
    Color txtColor = isGreen ? Colors.green.shade700 : isRed ? Colors.red.shade700 : Colors.black87;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(
          "${_selectedCurrency == 'USD' ? '\$ ' : ''}${val.toStringAsFixed(_selectedCurrency == 'USD' ? 2 : 0)} $_selectedCurrency",
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: txtColor),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}