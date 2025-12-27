class AccountClosingModel {
  String id;
  String companyid;
  String serialNo;
  String date;
  String customerId;
  String customerName;
  String loanId;
  String loanNo;
  String loanAmount;
  String loanPaid;
  String balanceAmount;
  String penaltyAmount;
  String penaltyCollected;
  String penaltyBalance;
  String discountPrinciple;
  String discountPenalty;
  String finalSettlement;
  String addedby;
  String createdAt;

  AccountClosingModel({
    required this.id,
    required this.companyid,
    required this.serialNo,
    required this.date,
    required this.customerId,
    required this.customerName,
    required this.loanId,
    required this.loanNo,
    required this.loanAmount,
    required this.loanPaid,
    required this.balanceAmount,
    required this.penaltyAmount,
    required this.penaltyCollected,
    required this.penaltyBalance,
    required this.discountPrinciple,
    required this.discountPenalty,
    required this.finalSettlement,
    required this.addedby,
    required this.createdAt,
  });

  factory AccountClosingModel.fromJson(Map<String, dynamic> json) {
    return AccountClosingModel(
      id: json['id']?.toString() ?? '',
      companyid: json['companyid']?.toString() ?? '',
      serialNo: json['serial_no']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? '',
      loanId: json['loan_id']?.toString() ?? '',
      loanNo: json['loan_no']?.toString() ?? '',
      loanAmount: json['loan_amount']?.toString() ?? '0.00',
      loanPaid: json['loan_paid']?.toString() ?? '0.00',
      balanceAmount: json['balance_amount']?.toString() ?? '0.00',
      penaltyAmount: json['penalty_amount']?.toString() ?? '0.00',
      penaltyCollected: json['penalty_collected']?.toString() ?? '0.00',
      penaltyBalance: json['penalty_balance']?.toString() ?? '0.00',
      discountPrinciple: json['discount_principle']?.toString() ?? '0.00',
      discountPenalty: json['discount_penalty']?.toString() ?? '0.00',
      finalSettlement: json['final_settlement']?.toString() ?? '0.00',
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
      'customer_id': customerId,
      'customer_name': customerName,
      'loan_id': loanId,
      'loan_no': loanNo,
      'loan_amount': loanAmount,
      'loan_paid': loanPaid,
      'balance_amount': balanceAmount,
      'penalty_amount': penaltyAmount,
      'penalty_collected': penaltyCollected,
      'penalty_balance': penaltyBalance,
      'discount_principle': discountPrinciple,
      'discount_penalty': discountPenalty,
      'final_settlement': finalSettlement,
      'addedby': addedby,
      'created_at': createdAt,
    };
  }

  // Helper methods
  double get loanAmountValue => double.tryParse(loanAmount) ?? 0.0;
  double get loanPaidValue => double.tryParse(loanPaid) ?? 0.0;
  double get balanceAmountValue => double.tryParse(balanceAmount) ?? 0.0;
  double get penaltyAmountValue => double.tryParse(penaltyAmount) ?? 0.0;
  double get penaltyCollectedValue => double.tryParse(penaltyCollected) ?? 0.0;
  double get penaltyBalanceValue => double.tryParse(penaltyBalance) ?? 0.0;
  double get discountPrincipleValue => double.tryParse(discountPrinciple) ?? 0.0;
  double get discountPenaltyValue => double.tryParse(discountPenalty) ?? 0.0;
  double get finalSettlementValue => double.tryParse(finalSettlement) ?? 0.0;

  String get formattedDate {
    try {
      DateTime dt = DateTime.parse(date);
      return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
    } catch (e) {
      return date;
    }
  }

  String get formattedLoanAmount => "₹${loanAmountValue.toStringAsFixed(2)}";
  String get formattedLoanPaid => "₹${loanPaidValue.toStringAsFixed(2)}";
  String get formattedBalanceAmount => "₹${balanceAmountValue.toStringAsFixed(2)}";
  String get formattedPenaltyAmount => "₹${penaltyAmountValue.toStringAsFixed(2)}";
  String get formattedPenaltyCollected => "₹${penaltyCollectedValue.toStringAsFixed(2)}";
  String get formattedPenaltyBalance => "₹${penaltyBalanceValue.toStringAsFixed(2)}";
  String get formattedFinalSettlement => "₹${finalSettlementValue.toStringAsFixed(2)}";
}