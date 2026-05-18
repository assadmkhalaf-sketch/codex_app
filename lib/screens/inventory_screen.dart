// ignore_for_file: dead_code, dead_null_aware_expression

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../language_data.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final supabase = Supabase.instance.client;
  final _searchController = TextEditingController();
  List<dynamic> _inventoryItems = [];
  List<dynamic> _filteredItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchInventory();
  }

  // جلب البيانات من جدول المنتجات الرئيسي
  Future<void> _fetchInventory() async {
    setState(() => _isLoading = true);
    try {
      final data = await supabase
          .from('products')
          .select()
          .order('name', ascending: true);

      setState(() {
        _inventoryItems = data;
        _filteredItems = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching inventory: $e");
      setState(() => _isLoading = false);
    }
  }

  // دالة حذف مادة نهائياً مع حماية الـ BuildContext
  Future<void> _deleteProduct(int id) async {
    try {
      await supabase.from('products').delete().eq('id', id);
      
      // جلب البيانات مجدداً لتحديث القائمة في الخلفية
      await _fetchInventory(); 

      // الحارس الذكي: التحقق من أن الشاشة ما زالت قائمة قبل إظهار الـ SnackBar
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.get('success_update') ?? "تم التحديث بنجاح")),
      );
    } catch (e) {
      debugPrint("Delete Error: $e");
    }
  }

  // نافذة تأكيد الحذف
  void _confirmDelete(int id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(name),
        content: Text(AppStrings.get('delete_confirm') ?? "هل أنت متأكد من الحذف؟"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.get('cancel') ?? "إلغاء"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteProduct(id);
            },
            child: const Text("حذف", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _searchProduct(String query) {
    setState(() {
      _filteredItems = _inventoryItems
          .where((item) => item['name']
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isRtl = AppStrings.currentLang != 'en';

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.get('inventory') ?? "المستودع"),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                onChanged: _searchProduct,
                decoration: InputDecoration(
                  hintText: AppStrings.get('search_hint') ?? "بحث...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: _filteredItems.length,
                itemBuilder: (context, index) {
                  final item = _filteredItems[index];

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item['name'] ?? "بدون اسم",
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _confirmDelete(item['id'], item['name']),
                              ),
                            ],
                          ),
                          // عرض اسم المورد
                          _infoRow(Icons.person, "${AppStrings.get('supplier_name')}: ${item['last_supplier'] ?? '---'}"),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _priceTag("\$ ${item['price_usd']}", Colors.green),
                              const SizedBox(width: 10),
                              _priceTag("${item['price_iqd']} IQD", Colors.blue),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${AppStrings.get('stock')}: ${item['stock']}",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: (item['stock'] ?? 0) < 5 ? Colors.red : Colors.teal,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: Colors.black87, fontSize: 14)),
      ],
    );
  }

  Widget _priceTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        // استخدام دالة معالجة الألوان الحديثة من فلاتر لعام 2026 لإنهاء التنبيه تماماً
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}