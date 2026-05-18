class AppStrings {
  static String currentLang = 'ar';

  // القاموس الذكي: تم توحيد جميع الكلمات داخل خريطة واحدة
  static const Map<String, Map<String, String>> _data = {
    // العناوين الرئيسية والداشبورد
    'dashboard': {'ar': 'الرئيسية', 'ku': 'سەرەکی', 'en': 'Dashboard'},
    'inventory': {'ar': 'المخزن', 'ku': 'کۆگا', 'en': 'Inventory'},
    'settings': {'ar': 'الإعدادات', 'ku': 'ڕێکخستنەکان', 'en': 'Settings'},
    'sales': {'ar': 'المبيعات', 'ku': 'فرۆشتن', 'en': 'Sales'},
    'quick_actions': {'ar': 'إجراءات سريعة', 'ku': 'کارە خێراکان', 'en': 'Quick Actions'},

    // الزبائن والموردين
    'customers': {'ar': 'زبائن', 'ku': 'کڕیاران', 'en': 'Customers'},
    'suppliers': {'ar': 'موردين', 'ku': 'دابینکەران', 'en': 'Suppliers'},
    'customer_name': {'ar': 'اسم الزبون', 'ku': 'ناوی کڕیار', 'en': 'Customer Name'},
    'supplier_name': {'ar': 'اسم المورد', 'ku': 'ناوی دابینکەر', 'en': 'Supplier Name'},
    'customer_debts': {'ar': 'ديون الزبائن', 'ku': 'قەرزەکانی کڕیار', 'en': 'Customer Debts'},
    'supplier_debts': {'ar': 'ديون الموردين', 'ku': 'قەرزەکانی دابینکەر', 'en': 'Supplier Debts'},
    'search_customer': {'ar': 'ابحث عن زبون...', 'ku': 'بگەڕێ بۆ کڕیار...', 'en': 'Search for a customer...'},
    'search_supplier': {'ar': 'ابحث عن مورد...', 'ku': 'بگەڕێ بۆ دابینکەر...', 'en': 'Search for a supplier...'},
    'no_debts': {'ar': 'لا توجد ديون حالياً', 'ku': 'هیچ قەرزێک نییە', 'en': 'No outstanding debts'},
    'no_supplier_debts': {'ar': 'لا توجد ديون للموردين', 'ku': 'هیچ قەرزێکی دابینکەران نییە', 'en': 'No debts to suppliers'},

    // المشتريات والمبيعات
    'purchase_invoice': {'ar': 'فاتورة شراء', 'ku': 'وەسڵی کڕین', 'en': 'Purchase Invoice'},
    'sales_list': {'ar': 'قائمة المبيعات', 'ku': 'لیستی فرۆشتن', 'en': 'Sales List'},
    'total_bill': {'ar': 'إجمالي الفاتورة', 'ku': 'کۆی گشتی پسوولە', 'en': 'Total Bill'},
    'paid_amount': {'ar': 'المبلغ المدفوع', 'ku': 'بڕی دراو', 'en': 'Paid Amount'},
    'remaining_amount': {'ar': 'المبلغ المتبقي', 'ku': 'بڕی ماوە', 'en': 'Remaining Amount'},
    'confirm_sale': {'ar': 'تأكيد البيع', 'ku': 'پشتڕاستکردنەوەی فرۆشتن', 'en': 'Confirm Sale'},
    'sell_now': {'ar': 'بيع الآن', 'ku': 'فرۆشتن ئێستا', 'en': 'Sell Now'},
    'units': {'ar': 'وحدة', 'ku': 'دانە', 'en': 'Units'},
    'stock': {'ar': 'المخزن', 'ku': 'مەوجود', 'en': 'Stock'},

    // تنبيهات وأزرار عامة
    'search_hint': {'ar': 'ابحث هنا...', 'ku': 'لێرە بگەڕێ...', 'en': 'Search here...'},
    'save': {'ar': 'حفظ', 'ku': 'پاشەکەوت', 'en': 'Save'},
    'cancel': {'ar': 'إلغاء', 'ku': 'پاشگەزبوونەوە', 'en': 'Cancel'},
    'success_update': {'ar': 'تم بنجاح', 'ku': 'سەرکەوتوو بوو', 'en': 'Success'},
    'delete_confirm': {'ar': 'هل أنت متأكد؟', 'ku': 'دڵنیای؟', 'en': 'Are you sure?'},
    'name': {'ar': 'اسم المادة', 'ku': 'ناوی بابەت', 'en': 'Product Name'},
    'search_or_add': {
      'ar': 'ابحث عن زبون أو اكتب اسماً جديداً...',
      'ku': 'بگەڕێ بۆ کڕیار یان ناوێکی نوێ بنووسە...',
      'en': 'Search for a customer or type a new name...',
    },
    'price': {'ar': 'السعر', 'ku': 'نرخ', 'en': 'Price'},
    'sale_price': {
      'ar': 'سعر البيع',
      'ku': 'نرخی فرۆشتن',
      'en': 'Sale Price',
    },

    'invoice_no': {'ar': 'رقم الفاتورة', 'ku': 'ژمارەی پسوولە', 'en': 'Inv No'},
    'sale_date': {'ar': 'تاريخ البيع', 'ku': 'بەرواری فرۆشتن', 'en': 'Sale Date'},
    'items_count': {'ar': 'عدد المواد', 'ku': 'ژمارەی بابەتەکان', 'en': 'Items'},

    'financial_summary': {'ar': 'الملخص المالي', 'ku': 'کورتەی دارایی', 'en': 'Financial Summary'},
    'total_capital': {'ar': 'رأس المال (المخزن)', 'ku': 'سەرمایە (کۆگا)', 'en': 'Total Capital (Stock)'},
    'total_receivable': {'ar': 'ديون الزبائن (لنا)', 'ku': 'قەرزی کڕیار (بۆ ئێمە)', 'en': 'Customer Debts (Receivable)'},
    'total_payable': {'ar': 'ديون الموردين (علينا)', 'ku': 'قەرزی دابینکەر (لەسەر ئێمە)', 'en': 'Supplier Debts (Payable)'},
    'net_worth': {'ar': 'صافي القيمة المالية', 'ku': 'کۆی گشتی دارایی', 'en': 'Net Financial Value'},
    'expenses': {'ar': 'المصاريف', 'ku': 'خەرجییەکان', 'en': 'Expenses'},
    'add_expense': {'ar': 'إضافة مصروف', 'ku': 'زیادکردنی خەرجی', 'en': 'Add Expense'},
    'expense_reason': {'ar': 'سبب الصرف', 'ku': 'هۆکاری خەرجی', 'en': 'Reason'},
    'expense_amount': {'ar': 'المبلغ المصروف', 'ku': 'بڕی خەرجکراو', 'en': 'Amount'},

    'pay_debt': {'ar': 'تسديد دين', 'ku': 'دانەوەی قەرز', 'en': 'Pay Debt'},
    'amount_paid': {'ar': 'المبلغ المدفوع', 'ku': 'بڕی پارەی دراو', 'en': 'Paid Amount'},
    'print_invoice': {'ar': 'طباعة فاتورة', 'ku': 'چاپکردنی پسوڵە', 'en': 'Print Invoice'},
    'remaining_balance': {'ar': 'المتبقي بذمته', 'ku': 'قەرزی ماوە', 'en': 'Remaining Balance'},

    'receipt_number': {'ar': 'رقم الوصل', 'ku': 'ژمارەی پسوڵە', 'en': 'Receipt Number'},

    'payments_management': {'ar': 'إدارة التسديدات', 'ku': 'بەڕێوەبردنی پارەدانەکان', 'en': 'Payments Management'},
    'new_payment': {'ar': 'وصل تسديد جديد', 'ku': 'پسوڵەی پارەدانی نوێ', 'en': 'New Payment Receipt'},
    'select_person': {'ar': 'اختر الشخص (زبون/مورد)', 'ku': 'کەسەکە هەڵبژێرە', 'en': 'Select Person'},
    'payment_success': {'ar': 'تم التسديد وتحديث الرصيد بنجاح', 'ku': 'پارەدان و نوێکردنەوەی باڵانس سەرکەوتوو بوو', 'en': 'Payment successful and balance updated'},

    'invoice': {'ar': 'فاتورة', 'ku': 'پسوڵە', 'en': 'Invoice'},
    'date': {'ar': 'التاريخ', 'ku': 'بەروار', 'en': 'Date'},
    'total': {'ar': 'الإجمالي', 'ku': 'کۆی گشتی', 'en': 'Total'},
    'item_name': {'ar': 'المادة', 'ku': 'بابەت', 'en': 'Item'},
    'qty': {'ar': 'الكمية', 'ku': 'دانە', 'en': 'Qty'},

    // مفاتيح منظومة طباعة وصولات التسديدات
    'receipt_voucher': {'ar': 'وصل قبض مالي', 'ku': 'پسوولەی وەرگرتنی پارە', 'en': 'Receipt Voucher'},
    'payment_voucher': {'ar': 'وصل دفع مالي', 'ku': 'پسوولەی دانی پارە', 'en': 'Payment Voucher'},
    'notes': {'ar': 'الملاحظات', 'ku': 'تێبینیەکان', 'en': 'Notes'},
    'financial_field': {'ar': 'الحقل المالي', 'ku': 'بۆشایی دارایی', 'en': 'Financial Field'},
    'statement_details': {'ar': 'البيان والتفاصيل', 'ku': 'بەیان و ووردەکاری', 'en': 'Statement & Details'},
    'print_date': {'ar': 'تاريخ الطبع', 'ku': 'ڕێکەوتی چاپکردن', 'en': 'Print Date'},
    'pdf_footer_note': {
      'ar': 'نظام إدارة الحسابات والشركات المطور لـ إمبراطورية البرمجيات Code X', 
      'ku': 'سیستەمی گەشەپێدراوی بەڕێوەبردنی ژمێریاری و کۆمپانیاکان بۆ ئیمپراتۆریەتی سۆفتوێری Code X', 
      'en': 'Advanced Accounting & Business Management System - Code X Software Empire'
    },
    'new_process': {'ar': 'عملية جديدة', 'ku': 'کردارێکی نوێ', 'en': 'New Process'},
    'print': {'ar': 'طباعة فورية', 'ku': 'چاپکردنی ڕاستەوخۆ', 'en': 'Direct Print'},
    'save_only': {'ar': 'حفظ البيانات فقط', 'ku': 'تەنها پاشەکەوتکردنی زانیارییەکان', 'en': 'Save Data Only'},
    'preview_print': {'ar': 'معاينة وطباعة الوصل', 'ku': 'پێشاندان و چاپکردنی پسوولە', 'en': 'Preview & Print Voucher'},
     
     'ar': {
      'customers': 'كشف حسابات الزبائن',
      'suppliers': 'كشف حسابات الموردين',
      'search_hint': 'بحث عن اسم...',
      'invoice': 'فاتورة مبيعات',
      'purchase_invoice': 'فاتورة مشتريات',
      'total_amount': 'الإجمالي الكلي',
      'paid_amount': 'إجمالي الواصل',
      'remaining_amount': 'صافي الدين المتبقي',
      'initial_paid': 'دفعة أولية عند تنظيم الوصل',
      'sub_paid': 'قسط لاحق',
      'no_invoices': 'لا توجد فواتير مسجلة لهذه العملة',
      'delete_title': 'حذف نهائي',
      'print_btn': 'طباعة التقرير والتسديدات',
      
      'general_statement': 'كشف حساب عام',
      'payment_receipt': 'سند قبض مالي',
      'disbursement_receipt': 'سند صرف مالي',
      'supplier_total_invoices': 'إجمالي المشتريات (الفواتير المستلمة):',
      'customer_total_invoices': 'إجمالي المسحوبات (الفواتير الصادرة):',
      'total_paid_amount': 'إجمالي المبالغ المسددة (الواصل):',
      'remaining_debt_balance': 'صافي الدين المتبقي في الذمة:',
      'sales_invoice_title': 'فاتورة مبيعات',
      'purchase_invoice_title': 'فاتورة مشتريات',
      'down_payment_prefix': 'دفعة أولى',
    },
    'ku': {
      'customers': 'کشف حسابی کڕیاران',
      'suppliers': 'کشف حسابی دابینکەران',
      'search_hint': 'گەڕان بەدوای ناو...',
      'invoice': 'فاکتۆری فرۆشتن',
      'purchase_invoice': 'فاکتۆری کڕین',
      'total_amount': 'کۆیی گشتی',
      'paid_amount': 'بڕی دراو (واسل)',
      'remaining_amount': 'ماوەی قەرز (کۆتایی)',
      'initial_paid': 'پێشەکی لە کاتی ڕێکخستنی فاکتۆر',
      'sub_paid': 'قیستی دواتر',
      'no_invoices': 'هیچ فاکتۆرێک تۆمار نەکراوە بۆ ئەم دراوە',
      'delete_title': 'سڕینەوەی یەکجاری',
      'print_btn': 'چاپکردنی ڕاپۆرت و بڕی دراوەکان',
       
      'general_statement': 'کشف حسابی گشتی',
      'payment_receipt': 'سەنەدی وەرگرتن',
      'disbursement_receipt': 'سەنەدی سەرف',
      'supplier_total_invoices': 'کۆیی گشتی کڕینەکان (فاکتۆرەکان):',
      'customer_total_invoices': 'کۆیی گشتی فرۆشتنەکان (فاکتۆرەکان):',
      'total_paid_amount': 'کۆیی گشتی بڕی دراو (واسل):',
      'remaining_debt_balance': 'صافی ماوەی قەرز (کۆتایی):',
      'sales_invoice_title': 'فاکتۆری فرۆشتن',
      'purchase_invoice_title': 'فاکتۆری کڕین',
      'down_payment_prefix': 'پێشەکی',
    },
    
    
   
    'en': {
      'search_hint': 'Search for name...',
      'general_statement': 'General Statement',
      'payment_receipt': 'Payment Receipt',
      'disbursement_receipt': 'Disbursement Receipt',
      'supplier_total_invoices': 'Total Purchases (Received Invoices):',
      'customer_total_invoices': 'Total Sales (Issued Invoices):',
      'total_paid_amount': 'Total Paid Amount:',
      'remaining_debt_balance': 'Net Remaining Debt:',
      'sales_invoice_title': 'Sales Invoice',
      'purchase_invoice_title': 'Purchase Invoice',
      'down_payment_prefix': 'Down Payment',
    }
  };

  

  

  // الدالة الذكية لجلب النص
  static String get(String key) {
    return _data[key]?[currentLang] ?? key;
  }
}