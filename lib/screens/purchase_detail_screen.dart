// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../language_data.dart';

class PurchaseDetailScreen extends StatefulWidget {
  final int purchaseId;
  final int supplierId;
  final String supplierName;
  final String currency;
  final double totalInvoiceAmount;
  final String invoiceDate;

  const PurchaseDetailScreen({
    super.key,
    required this.purchaseId,
    required this.supplierId,
    required this.supplierName,
    required this.currency,
    required this.totalInvoiceAmount,
    required this.invoiceDate,
  });

  @override
  State<PurchaseDetailScreen> createState() => _PurchaseDetailScreenState();
}

class _PurchaseDetailScreenState extends State<PurchaseDetailScreen> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<dynamic> _invoiceItems = [];
  List<dynamic> _invoicePayments = [];
  
  double _initialPaidAmount = 0; // الدفعة الأولية من الفاتورة الصادرة للمورد
  double _totalPaidOnThisInvoice = 0; // إجمالي المسدد (الأولية + السندات اللاحقة)

  @override
  void initState() {
    super.initState();
    _loadPurchaseDetailsAndPayments();
  }

  Future<void> _loadPurchaseDetailsAndPayments() async {
    setState(() => _isLoading = true);
    try {
      // 1. جلب بيانات الدفعة الأولية من الفاتورة بجدول purchases (حقل paid_amount الكسري والآمن)
      final purchaseData = await supabase
          .from('purchases')
          .select('paid_amount')
          .eq('id', widget.purchaseId)
          .single();

      double initialPaid = 0.0;
      if (purchaseData['paid_amount'] != null) {
        initialPaid = (purchaseData['paid_amount'] is num) 
            ? (purchaseData['paid_amount'] as num).toDouble() 
            : 0.0;
      }

      // 2. جلب المواد المشتراة داخل الفاتورة
      List<dynamic> itemsData = [];
      try {
        itemsData = await supabase.from('purchase_items').select('product_name, quantity, unit_price').eq('purchase_id', widget.purchaseId);
      } catch (_) {
        itemsData = await supabase.from('purchases_items').select('product_name, quantity, unit_price').eq('purchase_id', widget.purchaseId);
      }

      // 3. جلب سندات الصرف اللاحقة للمورد بناء على الحساب المفتوح الموحد
      final paymentsData = await supabase
          .from('payments')
          .select('id, amount, created_at, receipt_number')
          .eq('person_id', widget.supplierId.toString())
          .eq('person_type', 'supplier')
          .eq('currency', widget.currency);

      double tempPaymentsPaid = 0;
      for (var p in paymentsData) {
        tempPaymentsPaid += (p['amount'] is num) ? (p['amount'] as num).toDouble() : 0.0;
      }

      setState(() {
        _invoiceItems = itemsData;
        _invoicePayments = paymentsData;
        _initialPaidAmount = initialPaid;
        _totalPaidOnThisInvoice = _initialPaidAmount + tempPaymentsPaid;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Load Purchase Details Error: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _printPurchaseReceipt() async {
    final pdf = pw.Document();
    pw.Font? customFont;
    try {
      final data = await DefaultAssetBundle.of(context).load("assets/fonts/NotoSansArabic.ttf");
      customFont = pw.Font.ttf(data);
    } catch (_) {
      customFont = pw.Font.helvetica();
    }

    // فحص اتجاه اللغة لتقرير الـ PDF للموردين
    bool isPdfRtl = AppStrings.currentLang != 'en';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(base: customFont, bold: customFont),
        build: (pw.Context context) {
          return [
            pw.Directionality(
              textDirection: isPdfRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Center(child: pw.Text(AppStrings.currentLang == 'ku' ? "فاکتۆری کڕین و وردەکاری ئەستۆپاکی یەکگرتووی دابینکەر" : AppStrings.currentLang == 'en' ? "Purchase Invoice & Supplier Unified Statement" : "فاتورة شراء وتفاصيل ذمة المورد الموحدة", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900))),
                  pw.Center(child: pw.Text(AppStrings.currentLang == 'ku' ? "سیستەمی Code X بۆ بەڕێوبردنی حسابات" : AppStrings.currentLang == 'en' ? "Code X Accounting Management System" : "نظام Code X لإدارة الحسابات", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600))),
                  pw.SizedBox(height: 15),
                  pw.Text("${AppStrings.currentLang == 'ku' ? 'ژمارەی فاکتۆری دابینکردن' : AppStrings.currentLang == 'en' ? 'Supply Invoice No' : 'رقم فاتورة التجهيز'}: #${widget.purchaseId}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text("${AppStrings.currentLang == 'ku' ? 'ناوی کۆمپانیا / دابینکەر' : AppStrings.currentLang == 'en' ? 'Company / Supplier Name' : 'اسم الشركة / المورد'}: ${widget.supplierName}"),
                  pw.Text("${AppStrings.currentLang == 'ku' ? 'ڕێکەوتی فاکتۆر' : AppStrings.currentLang == 'en' ? 'Invoice Date' : 'تاريخ الفاتورة'}: ${widget.invoiceDate}"),
                  pw.SizedBox(height: 15),
                  
                  pw.Text(AppStrings.currentLang == 'ku' ? "یەکەم: ئەو ماددانەی کە لە دابینکەرەوە وەرگیراون:" : AppStrings.currentLang == 'en' ? "First: Items Received from Supplier:" : "أولاً: المواد المستلمة من المورد:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.teal700)),
                  pw.SizedBox(height: 5),
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300),
                    children: [
                      pw.TableRow(decoration: const pw.BoxDecoration(color: PdfColors.grey100), children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(AppStrings.currentLang == 'ku' ? "ماددە" : AppStrings.currentLang == 'en' ? "Item" : "المادة")),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(AppStrings.currentLang == 'ku' ? "بڕی دابینکراو" : AppStrings.currentLang == 'en' ? "Supplied Qty" : "الكمية الموردة")),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(AppStrings.currentLang == 'ku' ? "کۆیی گشتی" : AppStrings.currentLang == 'en' ? "Total Price" : "السعر الإجمالي")),
                      ]),
                      ..._invoiceItems.map((itm) {
                        double price = (itm['unit_price'] is num) ? (itm['unit_price'] as num).toDouble() : 0.0;
                        int q = itm['quantity'] ?? 1;
                        return pw.TableRow(children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(itm['product_name'] ?? "")),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(q.toString())),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("${q * price} ${widget.currency}")),
                        ]);
                      })
                    ]
                  ),
                  
                  pw.SizedBox(height: 20),
                  pw.Text(AppStrings.currentLang == 'ku' ? "دووەم: تۆماری بڕە پارەکان و وەرگرتنی دابینکەر و کۆمپانیا:" : AppStrings.currentLang == 'en' ? "Second: Paid Amounts & Receipts Record for Supplier/Company:" : "ثانياً: سجل المبالغ والواصل المدفوع للمورد والشركة:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.green700)),
                  pw.SizedBox(height: 5),
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300),
                    children: [
                      pw.TableRow(decoration: const pw.BoxDecoration(color: PdfColors.grey100), children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(AppStrings.currentLang == 'ku' ? "ڕێکەوت" : AppStrings.currentLang == 'en' ? "Date" : "التاريخ")),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(AppStrings.currentLang == 'ku' ? "ڕوونکردنەوەی سروشتی سەنەدی سەرف" : AppStrings.currentLang == 'en' ? "Disbursement Receipt Nature Statement" : "بيان طبيعة مستند الصرف")),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(AppStrings.currentLang == 'ku' ? "بڕی پارەی پێدراو" : AppStrings.currentLang == 'en' ? "Amount Paid" : "المبلغ المدفوع له")),
                      ]),
                      if (_initialPaidAmount > 0)
                        pw.TableRow(children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(widget.invoiceDate)),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(AppStrings.get('initial_paid'))),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("$_initialPaidAmount ${widget.currency}")),
                        ]),
                      ..._invoicePayments.map((p) {
                        double pAmount = (p['amount'] is num) ? (p['amount'] as num).toDouble() : 0.0;
                        return pw.TableRow(children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(p['created_at'].toString().split('T')[0])),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(AppStrings.currentLang == 'ku' ? "سەنەدی سەرفی دواتر (ژمارەی #${p['receipt_number'] ?? p['id'].toString()})" : AppStrings.currentLang == 'en' ? "Subsequent Disbursement (No #${p['receipt_number'] ?? p['id'].toString()})" : "سند صرف لاحق (رقم #${p['receipt_number'] ?? p['id'].toString()})")),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("$pAmount ${widget.currency}")),
                        ]);
                      })
                    ]
                  ),
                        
                  pw.SizedBox(height: 20),
                  pw.Divider(),
                  pw.Text("${AppStrings.currentLang == 'ku' ? 'کۆیی گشتی فاکتۆری کڕین' : AppStrings.currentLang == 'en' ? 'Total Amount for Purchase Invoice' : 'المبلغ الإجمالي لفاتورة التجهيز'}: ${widget.totalInvoiceAmount} ${widget.currency}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
                  pw.Text("${AppStrings.currentLang == 'ku' ? 'کۆیی گشتی پێدراوەکانمان' : AppStrings.currentLang == 'en' ? 'Total of Our Payments to Supplier' : 'إجمالي مدفوعاتنا الكلية له'}: $_totalPaidOnThisInvoice ${widget.currency}", style: pw.TextStyle(color: PdfColors.green900, fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.Text("${AppStrings.get('remaining_debt_balance')}: ${widget.totalInvoiceAmount - _totalPaidOnThisInvoice} ${widget.currency}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.red900, fontSize: 13)),
                ],
              ),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save(), name: "Purchase-Detail-${widget.purchaseId}");
  }

  @override
  Widget build(BuildContext context) {
    double remainingOnInvoice = widget.totalInvoiceAmount - _totalPaidOnThisInvoice;
    bool isRtl = AppStrings.currentLang != 'en';

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(AppStrings.currentLang == 'ku' ? "وردەکاری فاکتۆری کڕین #${widget.purchaseId}" : AppStrings.currentLang == 'en' ? "Purchase Invoice Details #${widget.purchaseId}" : "تفاصيل فاتورة الشراء #${widget.purchaseId}"),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.teal[50], borderRadius: BorderRadius.circular(15)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${AppStrings.currentLang == 'ku' ? 'کۆمپانیا / دابینکەر' : AppStrings.currentLang == 'en' ? 'Company / Supplier' : 'الشركة / المورد'}: ${widget.supplierName}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text("${AppStrings.currentLang == 'ku' ? 'ڕێکەوتی ڕێکخستنی فاکتۆر' : AppStrings.currentLang == 'en' ? 'Invoice Organization Date' : 'تاريخ تنظيم الفاتورة'}: ${widget.invoiceDate}"),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(AppStrings.currentLang == 'ku' ? "بایەخی فاکتۆری کڕین:" : AppStrings.currentLang == 'en' ? "Purchase Invoice Amount:" : "قيمة فاتورة التجهيز:"),
                              Text("${widget.totalInvoiceAmount} ${widget.currency}", style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(AppStrings.get('total_paid_amount')),
                              Text("$_totalPaidOnThisInvoice ${widget.currency}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(AppStrings.get('remaining_debt_balance'), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              Text("${remainingOnInvoice > 0 ? remainingOnInvoice : 0} ${widget.currency}", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(AppStrings.currentLang == 'ku' ? "١. ئەو ماددانەی کە هاتوونەتە ناو کۆگا:" : AppStrings.currentLang == 'en' ? "1. Items Received in Warehouse:" : "1. المواد المستلمة بالمخازن:", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.teal)),
                    const SizedBox(height: 5),
                    Expanded(
                      flex: 3,
                      child: ListView.builder(
                        itemCount: _invoiceItems.length,
                        itemBuilder: (context, index) {
                          final item = _invoiceItems[index];
                          double price = (item['unit_price'] is num) ? (item['unit_price'] as num).toDouble() : 0.0;
                          int qty = item['quantity'] ?? 1;
                          return Card(
                            elevation: 0,
                            color: Colors.grey[50],
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              title: Text(item['product_name'] ?? ""),
                              subtitle: Text("${AppStrings.currentLang == 'ku' ? 'بڕی دابینکراو' : AppStrings.currentLang == 'en' ? 'Supplied Qty' : 'الكمية الموردة'}: $qty × $price"),
                              trailing: Text("${qty * price} ${widget.currency}", style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(),
                    Text(AppStrings.currentLang == 'ku' ? "٢. تۆماری حساب و پێدراوەکانی کۆمپانیا:" : AppStrings.currentLang == 'en' ? "2. Statement & Payments Record Issued to Company:" : "2. سجل الحساب والمدفوعات الصادرة له:", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green)),
                    const SizedBox(height: 5),
                    Expanded(
                      flex: 2,
                      child: (_initialPaidAmount == 0 && _invoicePayments.isEmpty)
                          ? Center(child: Text(AppStrings.currentLang == 'ku' ? "هیچ بڕە پارەیەک بۆ ئەم دابینکەرە تۆمار نەکراوە." : AppStrings.currentLang == 'en' ? "No payments registered for this supplier yet." : "لم يتم تسجيل مبالغ مسددة لهذا المورد بعد.", style: const TextStyle(color: Colors.grey, fontSize: 12)))
                          : ListView(
                              children: [
                                if (_initialPaidAmount > 0)
                                  Card(
                                    elevation: 0,
                                    color: Colors.green[50],
                                    child: ListTile(
                                      leading: const Icon(Icons.stars, color: Colors.green),
                                      title: Text(AppStrings.get('initial_paid')),
                                      subtitle: Text(widget.invoiceDate),
                                      trailing: Text("$_initialPaidAmount ${widget.currency}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                    ),
                                  ),
                                ..._invoicePayments.map((pay) {
                                  double pAmount = (pay['amount'] is num) ? (pay['amount'] as num).toDouble() : 0.0;
                                  return ListTile(
                                    leading: const Icon(Icons.check_circle, color: Colors.teal),
                                    title: Text("${AppStrings.currentLang == 'ku' ? 'سەنەدی سەرفی دواتر' : AppStrings.currentLang == 'en' ? 'Subsequent Disbursement' : 'سند صرف لاحق'} (${AppStrings.currentLang == 'ku' ? 'ژمارە' : AppStrings.currentLang == 'en' ? 'No' : 'رقم'} #${pay['receipt_number'] ?? pay['id']})"),
                                    subtitle: Text(pay['created_at'].toString().split('T')[0]),
                                    trailing: Text("$pAmount ${widget.currency}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                                  );
                                }),
                              ],
                            ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 55),
                        backgroundColor: Colors.teal,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: _printPurchaseReceipt,
                      icon: const Icon(Icons.print, color: Colors.white),
                      label: Text(
                        AppStrings.get('print_btn'), 
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
      ),
    );
  }
}