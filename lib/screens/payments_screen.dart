// ignore_for_file: use_build_context_synchronously

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:printing/printing.dart'; 
import 'package:pdf/pdf.dart';
import '../language_data.dart';
import '../services/pdf_service.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final supabase = Supabase.instance.client;
  
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _receiptController = TextEditingController();
  
  String _personType = 'customer'; 
  dynamic _selectedPerson;
  List<dynamic> _peopleList = [];
  String _currency = 'IQD';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPeople();
    _generateReceiptNumber(); 
  }

  void _generateReceiptNumber() {
    String timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
    String datePart = DateTime.now().toString().split(' ')[0].replaceAll('-', '');
    String prefix = _personType == 'customer' ? "REC" : "PAY";
    setState(() {
      _receiptController.text = "$prefix-$datePart-$timestamp";
    });
  }

  Future<void> _loadPeople() async {
    setState(() => _isLoading = true);
    final table = _personType == 'customer' ? 'customers' : 'suppliers';
    try {
      final data = await supabase.from(table).select().order('name');
      setState(() {
        _peopleList = data;
        _selectedPerson = null;
      });
    } catch (e) {
      debugPrint("Load Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 1. دالة الحفظ الصافية (تحفظ فقط في السيرفر)
  Future<void> _savePaymentOnly() async {
    if (_selectedPerson == null || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.get('select_person'))),
      );
      return;
    }

    setState(() => _isLoading = true);
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final table = _personType == 'customer' ? 'customers' : 'suppliers';
    final balanceField = _currency == 'USD' ? 'balance_usd' : 'balance_iqd';

    try {
      final dynamic currentId = _selectedPerson['id'];

      // إدخال الحركة في السيرفر
      await supabase.from('payments').insert({
        'person_id': currentId.toString(), 
        'person_type': _personType,
        'amount': amount,
        'currency': _currency,
        'note': _noteController.text,
        'receipt_number': _receiptController.text,
      });

      // تحديث الرصيد الحسابي للشخص
      final double currentBalance = (_selectedPerson[balanceField] ?? 0.0).toDouble();
      final double newBalance = currentBalance - amount;
      await supabase.from(table).update({balanceField: newBalance}).eq('id', currentId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.get('payment_success'))),
      );

    } catch (e) {
      debugPrint("Save Error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("خطأ في عملية الحفظ: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 2. دالة الطباعة الفورية الصافية المرتبطة بالكامل بالقاموس المركزي
  Future<void> _openPrintPreviewOnly() async {
    if (_selectedPerson == null || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.get('select_person'))),
      );
      return;
    }

    final String currentLang = AppStrings.currentLang; 
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    
    String savedTitle = _personType == 'customer'
        ? AppStrings.get('receipt_voucher')
        : AppStrings.get('payment_voucher');

    String keyReceipt = AppStrings.get('receipt_number');
    String keyName = AppStrings.get('name');
    String keyAmount = AppStrings.get('amount_paid');
    String keyNotes = AppStrings.get('notes');

    String labelField = AppStrings.get('financial_field');
    String labelDetails = AppStrings.get('statement_details');
    String labelDate = AppStrings.get('print_date');
    String footerText = AppStrings.get('pdf_footer_note');

    final String savedReceiptNumber = _receiptController.text;
    final String savedPersonName = _selectedPerson['name'].toString();
    final String savedNote = _noteController.text;

    try {
      final Uint8List pdfBytes = await PdfService.generateHtmlReportBytes(
        title: savedTitle,
        lang: currentLang,
        labelField: labelField,
        labelDetails: labelDetails,
        labelDate: labelDate,
        footerText: footerText,
        data: [
          {"label": keyReceipt, "value": savedReceiptNumber},
          {"label": keyName, "value": savedPersonName},
          {"label": keyAmount, "value": "$amount $_currency"},
          {"label": keyNotes, "value": savedNote.isEmpty ? "-" : savedNote},
        ],
      );

      // فتح طابعة النظام مباشرة دون واجهات منبثقة وسيطة
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: savedReceiptNumber, 
      );

    } catch (e) {
      debugPrint("Printing Error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("خطأ أثناء استدعاء الطابعة: $e"), backgroundColor: Colors.red),
      );
    }
  }

  void _resetScreenForNewProcess() {
    _amountController.clear();
    _noteController.clear();
    _generateReceiptNumber();
    _loadPeople();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("تم تصفير الحقول وجاهز لعملية جديدة")),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isRtl = AppStrings.currentLang != 'en';

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.get('payments_management')),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          actions: [
            // زر عملية جديدة مأخوذ من القاموس
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: AppStrings.get('new_process'),
              onPressed: _resetScreenForNewProcess,
            ),
            
            // زر الطباعة العلوي الموحد والمترجم بالكامل
            IconButton(
              icon: const Icon(Icons.print),
              tooltip: AppStrings.get('print'),
              onPressed: _openPrintPreviewOnly,
            )
          ],
        ),
        body: _isLoading && _peopleList.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // تم ربط نصوص الخيارات بالقاموس هنا للتخلص من الكلمات الإنجليزية الثابتة
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment(
                          value: 'customer', 
                          label: Text(AppStrings.get('customers'))
                        ),
                        ButtonSegment(
                          value: 'supplier', 
                          label: Text(AppStrings.get('suppliers'))
                        ),
                      ],
                      selected: {_personType},
                      onSelectionChanged: (val) {
                        setState(() {
                          _personType = val.first;
                        });
                        _loadPeople();
                        _generateReceiptNumber(); 
                      },
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _receiptController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: AppStrings.get('receipt_number'),
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<dynamic>(
                      value: _selectedPerson,
                      isExpanded: true,
                      hint: Text(AppStrings.get('select_person')),
                      decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      items: _peopleList.map((p) {
                        String bal = _currency == 'USD' ? "${p['balance_usd']} \$" : "${p['balance_iqd']} IQD";
                        return DropdownMenuItem(value: p, child: Text("${p['name']} ($bal)"));
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedPerson = val),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: AppStrings.get('amount_paid'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: RadioListTile<String>(title: const Text("IQD"), value: "IQD", groupValue: _currency, onChanged: (v) => setState(() => _currency = v!))),
                        Expanded(child: RadioListTile<String>(title: const Text("USD"), value: "USD", groupValue: _currency, onChanged: (v) => setState(() => _currency = v!))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        labelText: AppStrings.get('notes'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    // زر الحفظ الصافي في الأسفل (تم الإبقاء عليه وحده لتخفيف زحام الواجهة)
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _savePaymentOnly,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: _isLoading 
                          ? const SizedBox.shrink()
                          : const Icon(Icons.save, color: Colors.white),
                        label: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(AppStrings.get('save_only'), style: const TextStyle(color: Colors.white, fontSize: 18)),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _receiptController.dispose();
    super.dispose();
  }
}