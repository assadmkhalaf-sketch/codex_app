import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../language_data.dart';
import 'package:intl/intl.dart'; 
import 'dart:ui' as ui;// ستحتاج لإضافة intl في pubspec.yaml لتنسيق التاريخ

class SalesListScreen extends StatefulWidget {
  const SalesListScreen({super.key});

  @override
  State<SalesListScreen> createState() => _SalesListScreenState();
}

class _SalesListScreenState extends State<SalesListScreen> {
  final supabase = Supabase.instance.client;
  List<dynamic> _sales = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSales();
  }

  Future<void> _fetchSales() async {
    setState(() => _isLoading = true);
    try {
      // جلب الفواتير مع اسم الزبون المرتبط بها
      final data = await supabase
          .from('sales')
          .select('*, customers(name)')
          .order('created_at', ascending: false);

      setState(() {
        _sales = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isRtl = AppStrings.currentLang != 'en';

    return Directionality(
      textDirection: isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(title: Text(AppStrings.get('sales_list'))),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: _sales.length,
                itemBuilder: (context, index) {
                  final sale = _sales[index];
                  final DateTime date = DateTime.parse(sale['created_at']);
                  
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: sale['is_cash'] ? Colors.green.shade100 : Colors.orange.shade100,
                        child: Icon(
                          sale['is_cash'] ? Icons.check_circle : Icons.timer,
                          color: sale['is_cash'] ? Colors.green : Colors.orange,
                        ),
                      ),
                      title: Text(sale['customers']['name'] ?? "زبون عام"),
                      subtitle: Text(DateFormat('yyyy-MM-dd | hh:mm a').format(date)),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "${sale['total_amount']} ${sale['currency']}",
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                          Text(
                            sale['is_cash'] ? AppStrings.get('cash') : AppStrings.get('installments'),
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      onTap: () => _showSaleItems(sale['id']),
                    ),
                  );
                },
              ),
      ),
    );
  }

  // نافذة لعرض محتويات الفاتورة (المواد المبيعة)
  void _showSaleItems(int saleId) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => FutureBuilder(
        future: supabase.from('sales_items').select().eq('sale_id', saleId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
          final items = snapshot.data as List;
          
          return Container(
            padding: const EdgeInsets.all(16),
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              children: [
                Text(AppStrings.get('cart_items'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final itm = items[index];
                      return ListTile(
                        title: Text(itm['product_name']),
                        subtitle: Text("${itm['quantity']} × ${itm['unit_price']} ${itm['currency']}"),
                        trailing: Text("${itm['quantity'] * itm['unit_price']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}