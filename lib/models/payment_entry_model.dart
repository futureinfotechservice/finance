class PaymentEntryModel {
  String id;
  String companyid;
  String serialNo;
  String date;
  String paymentAccount;
  String paymentAccountId;
  String cashBank;
  String amount;
  String description;
  String addedby;
  String createdAt;

  PaymentEntryModel({
    required this.id,
    required this.companyid,
    required this.serialNo,
    required this.date,
    required this.paymentAccount,
    required this.paymentAccountId,
    required this.cashBank,
    required this.amount,
    required this.description,
    required this.addedby,
    required this.createdAt,
  });

  factory PaymentEntryModel.fromJson(Map<String, dynamic> json) {
    return PaymentEntryModel(
      id: json['id']?.toString() ?? '',
      companyid: json['companyid']?.toString() ?? '',
      serialNo: json['serial_no']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      paymentAccount: json['payment_account']?.toString() ?? '',
      paymentAccountId: json['payment_account_id']?.toString() ?? '',
      cashBank: json['cash_bank']?.toString() ?? 'Cash',
      amount: json['amount']?.toString() ?? '0.00',
      description: json['description']?.toString() ?? '',
      addedby: json['addedby']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyid': companyid,
      'serial_no': serialNo,
      'date': date,
      'payment_account': paymentAccount,
      'payment_account_id': paymentAccountId,
      'cash_bank': cashBank,
      'amount': amount,
      'description': description,
      'addedby': addedby,
      'created_at': createdAt,
    };
  }

  // Helper methods
  double get amountValue => double.tryParse(amount) ?? 0.0;

  DateTime get dateTime {
    try {
      return DateTime.parse(date);
    } catch (e) {
      return DateTime.now();
    }
  }

  String get formattedDate {
    try {
      DateTime dt = DateTime.parse(date);
      return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
    } catch (e) {
      return date;
    }
  }

  String get formattedAmount {
    final value = amountValue;
    return "₹${value.toStringAsFixed(2)}";
  }

  bool get isCash => cashBank.toLowerCase() == 'cash';
  bool get isBank => cashBank.toLowerCase() == 'bank';
}