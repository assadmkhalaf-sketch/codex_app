import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/foundation.dart';

class PdfService {
  
  /// بناء وتوليد بايتات المستند بشكل مترجم كلياً حسب لغة الواجهة النشطة
  static Future<Uint8List> generateHtmlReportBytes({
    required String title,
    required List<Map<String, String>> data,
    required String lang, 
    required String labelField, 
    required String labelDetails, 
    required String labelDate, 
    required String footerText, 
  }) async {
    final pdf = pw.Document();

    final bool isRtl = (lang == 'ar' || lang == 'ku');
    final pw.TextDirection direction = isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr;
    final pw.TextAlign textAlignment = isRtl ? pw.TextAlign.right : pw.TextAlign.left;

    pw.Font? customFont;
    try {
      final fontData = await rootBundle.load("assets/fonts/NotoSansArabic.ttf");
      customFont = pw.Font.ttf(fontData);
    } catch (e) {
      debugPrint("Font Load Warning: $e");
      customFont = pw.Font.helvetica(); 
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        theme: pw.ThemeData.withFont(base: customFont, bold: customFont),
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: direction,
            child: pw.Column(
              crossAxisAlignment: isRtl ? pw.CrossAxisAlignment.start : pw.CrossAxisAlignment.end,
              children: [
                
                // رأس الوصل الموحد لـ Code X (العنوان الرئيسي مترجم بالكامل الآن)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      title, // هنا يظهر العنوان المترجم القادم من الواجهة (وصل قبض / پسوولەی وەرگرتن)
                      style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)
                    ),
                    pw.Text(
                      "Code X Business System", 
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo700)
                    ),
                  ],
                ),
                pw.SizedBox(height: 6),
                pw.Divider(thickness: 2.5, color: PdfColors.indigo900),
                pw.SizedBox(height: 10),
                
                // التاريخ والوقت المترجم
                pw.Container(
                  width: double.infinity,
                  alignment: isRtl ? pw.Alignment.centerLeft : pw.Alignment.centerRight,
                  child: pw.Text(
                    "$labelDate: ${DateTime.now().toString().split(' ')[0]}", 
                    style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)
                  ),
                ),
                pw.SizedBox(height: 25),

                // الجدول الحسابي المرتب
                pw.Table(
                  columnWidths: {
                    0: const pw.FlexColumnWidth(4.0),
                    1: const pw.FlexColumnWidth(6.0),
                  },
                  border: pw.TableBorder.all(color: PdfColors.grey400, width: 1.0),
                  children: [
                    
                    // صف العناوين المترجم للجدول (الحقل المالي / البيان والتفاصيل)
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.indigo50),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          child: pw.Text(
                            labelField, 
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900, fontSize: 13),
                            textAlign: textAlignment
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          child: pw.Text(
                            labelDetails, 
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900, fontSize: 13),
                            textAlign: textAlignment
                          ),
                        ),
                      ],
                    ),

                    // تعبئة البيانات ديناميكياً بطريقة تضمن قراءة النصوص المترجمة للطرفين
                    ...data.map((row) {
                      final String keyLabel = row['label'] ?? "";
                      final String valueDetails = row['value'] ?? "";
                      
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                            child: pw.Text(
                              keyLabel, 
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: PdfColors.grey900),
                              textAlign: textAlignment
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                            child: pw.Text(
                              valueDetails, 
                              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey800),
                              textAlign: textAlignment
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
                
                // تذييل الوصل
                pw.Spacer(),
                pw.Divider(thickness: 0.8, color: PdfColors.grey400),
                pw.SizedBox(height: 5),
                pw.Align(
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    footerText, 
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }
}