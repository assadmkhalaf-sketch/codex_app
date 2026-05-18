// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../language_data.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final int invoiceId;
  final int customerId;
  final String customerName;
  final String currency;
  final double totalInvoiceAmount;
  final String invoiceDate;

  const InvoiceDetailScreen({
    super.key,
    required this.invoiceId,
    required this.customerId,
    required this.customerName,
    required this.currency,
    required this.totalInvoiceAmount,
    required this.invoiceDate,
  });

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<dynamic> _invoiceItems = [];
  List<dynamic> _invoicePayments = [];
  
  double _initialPaidAmount = 0; // الدفعة الأولية الخاصة بهذه الفاتورة
  double _totalPaidOnThisInvoice = 0; // إجمالي المسدد الكلي (الأولية + الأقساط)

  @override
  void initState() {
    super.initState();
    _loadInvoiceDetailsAndPayments();
  }

  Future<void> _loadInvoiceDetailsAndPayments() async {
    setState(() => _isLoading = true);
    try {
      // 1. جلب بيانات الفاتورة الأساسية للتحقق من الدفعة الأولية (paid_amount)
      final invoiceData = await supabase
          .from('sales')
          .select('paid_amount')
          .eq('id', widget.invoiceId)
          .single();

      double initialPaid = 0.0;
      if (invoiceData['paid_amount'] != null) {
        initialPaid = (invoiceData['paid_amount'] is num) 
            ? (invoiceData['paid_amount'] as num).toDouble() 
            : 0.0;
      }

      // 2. جلب المواد المشمولة بالفاتورة
      final itemsData = await supabase
          .from('sales_items')
          .select('product_name, quantity, unit_price')
          .eq('sale_id', widget.invoiceId);

      // 3. جلب الأقساط اللاحقة للزبون بناءً على الحساب المفتوح
      final paymentsData = await supabase
          .from('payments')
          .select('id, amount, created_at, receipt_number')
          .eq('person_id', widget.customerId.toString())
          .eq('person_type', 'customer')
          .eq('currency', widget.currency);

      double tempPaymentsPaid = 0;
      for (var p in paymentsData) {
        tempPaymentsPaid += (p['amount'] is num) ? (p['amount'] as num).toDouble() : 0.0;
      }

      setState(() {
        _invoiceItems = itemsData;
        _invoicePayments = paymentsData;
        _initialPaidAmount = initialPaid;
        
        // الحساب الموحد داخل شاشة التفاصيل: الدفعة الأولية للفاتورة + أقساط السندات اللاحقة
        _totalPaidOnThisInvoice = _initialPaidAmount + tempPaymentsPaid;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Load Details Error: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _printInvoiceReceipt() async {
    final pdf = pw.Document();
    pw.Font? customFont;
    try {
      final data = await DefaultAssetBundle.of(context).load("assets/fonts/NotoSansArabic.ttf");
      customFont = pw.Font.ttf(data);
    } catch (_) {
      customFont = pw.Font.helvetica();
    }

    // فحص اتجاه اللغة لتقرير الـ PDF (RTL للعربية والكردية و LTR للإنجليزية)
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
                  pw.Center(child: pw.Text(AppStrings.currentLang == 'ku' ? "فاکتۆری فرۆشتن و وردەکاری حسابی یەکگرتوو" : AppStrings.currentLang == 'en' ? "Sales Invoice & Unified Statement Details" : "فاتورة بيع وتفاصيل الحساب الموحد", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900))),
                  pw.Center(child: pw.Text(AppStrings.currentLang == 'ku' ? "سیستەمی Code X بۆ بەڕێوبردنی مبیعات و کۆگاکان" : AppStrings.currentLang == 'en' ? "Code X Management & Warehouse System" : "نظام Code X لإدارة المبيعات والمخازن", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600))),
                  pw.SizedBox(height: 15),
                  pw.Text("${AppStrings.currentLang == 'ku' ? 'ژمارەی فاکتۆر' : AppStrings.currentLang == 'en' ? 'Invoice No' : 'رقم الفاتورة'}: #${widget.invoiceId}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text("${AppStrings.currentLang == 'ku' ? 'ناوی کڕیار' : AppStrings.currentLang == 'en' ? 'Customer Name' : 'اسم الزبون'}: ${widget.customerName}"),
                  pw.Text("${AppStrings.currentLang == 'ku' ? 'ڕێکەوتی فاکتۆر' : AppStrings.currentLang == 'en' ? 'Invoice Date' : 'تاريخ الفاتورة'}: ${widget.invoiceDate}"),
                  pw.SizedBox(height: 15),
                  
                  pw.Text(AppStrings.currentLang == 'ku' ? "یەکەم: ئەو ماددانەی کە لە فاکتۆرەکەدا هەن:" : AppStrings.currentLang == 'en' ? "First: Items Included in Invoice:" : "أولاً: المواد المشمولة بالفاتورة:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.indigo700)),
                  pw.SizedBox(height: 5),
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300),
                    children: [
                      pw.TableRow(decoration: const pw.BoxDecoration(color: PdfColors.grey100), children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(AppStrings.currentLang == 'ku' ? "ماددە" : AppStrings.currentLang == 'en' ? "Item" : "المادة")),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(AppStrings.currentLang == 'ku' ? "بڕ" : AppStrings.currentLang == 'en' ? "Qty" : "الكمية")),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(AppStrings.currentLang == 'ku' ? "کۆیی گشتی" : AppStrings.currentLang == 'en' ? "Total Price" : "السعر الكلي")),
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
                  pw.Text(AppStrings.currentLang == 'ku' ? "دووەم: تۆماری دراوەکان و قیستەکانی کڕیار:" : AppStrings.currentLang == 'en' ? "Second: Customer Payments & Installments Record:" : "ثانياً: سجل تسديدات وأقساط الزبون المستلمة:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.green700)),
                  pw.SizedBox(height: 5),
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300),
                    children: [
                      pw.TableRow(decoration: const pw.BoxDecoration(color: PdfColors.grey100), children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(AppStrings.currentLang == 'ku' ? "ڕێکەوت" : AppStrings.currentLang == 'en' ? "Date" : "التاريخ")),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(AppStrings.currentLang == 'ku' ? "جۆری سەنەد / ژمارەی سەنەد" : AppStrings.currentLang == 'en' ? "Receipt Type / No" : "نوع السند / رقم السند")),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(AppStrings.currentLang == 'ku' ? "بڕی واسل" : AppStrings.currentLang == 'en' ? "Amount Paid" : "المبلغ الواصل")),
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
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(AppStrings.currentLang == 'ku' ? "قیستی دواتر (سەنەدی #${p['receipt_number'] ?? p['id'].toString()})" : AppStrings.currentLang == 'en' ? "Subsequent Installment (Receipt #${p['receipt_number'] ?? p['id'].toString()})" : "قسط لاحق (سند #${p['receipt_number'] ?? p['id'].toString()})")),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("$pAmount ${widget.currency}")),
                        ]);
                      })
                    ]
                  ),
                        
                  pw.SizedBox(height: 20),
                  pw.Divider(),
                  pw.Text("${AppStrings.currentLang == 'ku' ? 'کۆیی گشتی ئەم فاکتۆرە' : AppStrings.currentLang == 'en' ? 'Total Amount for This Invoice' : 'المبلغ الكلي لهذه الفاتورة'}: ${widget.totalInvoiceAmount} ${widget.currency}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
                  pw.Text("${AppStrings.get('total_paid_amount')}: $_totalPaidOnThisInvoice ${widget.currency}", style: pw.TextStyle(color: PdfColors.green900, fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.Text("${AppStrings.get('remaining_debt_balance')}: ${widget.totalInvoiceAmount - _totalPaidOnThisInvoice} ${widget.currency}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.red900, fontSize: 13)),
                ],
              ),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save(), name: "Invoice-Detail-${widget.invoiceId}");
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
          title: Text(AppStrings.currentLang == 'ku' ? "وردەکاری فاکتۆری #${widget.invoiceId}" : AppStrings.currentLang == 'en' ? "Invoice Details #${widget.invoiceId}" : "تفاصيل الفاتورة #${widget.invoiceId}"),
          backgroundColor: Colors.indigo,
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
                      decoration: BoxDecoration(color: Colors.blueGrey[50], borderRadius: BorderRadius.circular(15)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${AppStrings.currentLang == 'ku' ? 'کڕیار' : AppStrings.currentLang == 'en' ? 'Customer' : 'الزبون'}: ${widget.customerName}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text("${AppStrings.currentLang == 'ku' ? 'ڕێکەوتی ڕێکخستنی وەسڵ' : AppStrings.currentLang == 'en' ? 'Receipt Organization Date' : 'تاريخ تنظيم الوصل'}: ${widget.invoiceDate}"),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(AppStrings.currentLang == 'ku' ? "کۆیی گشتی فاکتۆر:" : AppStrings.currentLang == 'en' ? "Total Invoice Amount:" : "قيمة الفاتورة الكلية:"),
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
                    Text(AppStrings.currentLang == 'ku' ? "١. ماددەکان و کڕینەکان:" : AppStrings.currentLang == 'en' ? "1. Items & Purchases:" : "1. المواد والمشتريات:", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.indigo)),
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
                              subtitle: Text("${AppStrings.currentLang == 'ku' ? 'بڕ' : AppStrings.currentLang == 'en' ? 'Qty' : 'الكمية'}: $qty × $price"),
                              trailing: Text("${qty * price} ${widget.currency}", style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(),
                    Text(AppStrings.currentLang == 'ku' ? "٢. تۆماری قیستەکانی کڕیار و بڕی واسل الحقيقي:" : AppStrings.currentLang == 'en' ? "2. Customer Installments & Actual Paid Record:" : "2. سجل أقساط الزبون والواصل النفعي الحقيقي:", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green)),
                    const SizedBox(height: 5),
                    Expanded(
                      flex: 2,
                      child: (_initialPaidAmount == 0 && _invoicePayments.isEmpty)
                          ? Center(child: Text(AppStrings.currentLang == 'ku' ? "هیچ وەسڵێکی پارەدان بۆ ئەم کڕیارە نەدۆزرایەوە." : AppStrings.currentLang == 'en' ? "No payment receipts found for this customer." : "لم يتم العثور على وصولات سداد مسجلة لهذا الزبون.", style: const TextStyle(color: Colors.grey, fontSize: 12)))
                          : ListView(
                              children: [
                                // عرض الدفعة الأولية في قائمة الأقساط بالشاشة إذا كانت موجودة
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
                                // عرض الأقساط اللاحقة
                                ..._invoicePayments.map((pay) {
                                  double pAmount = (pay['amount'] is num) ? (pay['amount'] as num).toDouble() : 0.0;
                                  return ListTile(
                                    leading: const Icon(Icons.check_circle, color: Colors.blue),
                                    title: Text("${AppStrings.get('sub_paid')} (${AppStrings.currentLang == 'ku' ? 'سەنەدی' : AppStrings.currentLang == 'en' ? 'Receipt' : 'سند'} #${pay['receipt_number'] ?? pay['id']})"),
                                    subtitle: Text(pay['created_at'].toString().split('T')[0]),
                                    trailing: Text("$pAmount ${widget.currency}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                                  );
                                }),
                              ],
                            ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 55),
                        backgroundColor: Colors.indigo,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: _printInvoiceReceipt,
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