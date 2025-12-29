// outstanding_report_model.dart
class OutstandingReportItem {
  final String id;
  final String loanNo;
  final String customerName;
  final double loanAmount;
  final double interestAmount;
  final int noOfWeeks;
  final double penaltyAmount;
  final double collectionAmount;
  final double penaltyCollected;
  final double balancePrincipal;
  final double balancePenalty;
  final int weeksPaid;
  final int weeksBalance;
  final String loanStatus;
  final String startDate;

  OutstandingReportItem({
    required this.id,
    required this.loanNo,
    required this.customerName,
    required this.loanAmount,
    required this.interestAmount,
    required this.noOfWeeks,
    required this.penaltyAmount,
    required this.collectionAmount,
    required this.penaltyCollected,
    required this.balancePrincipal,
    required this.balancePenalty,
    required this.weeksPaid,
    required this.weeksBalance,
    required this.loanStatus,
    required this.startDate,
  });
}

class OutstandingSummary {
  final double totalLoanAmount;
  final double totalInterestAmount;
  final double totalPenaltyAmount;
  final double totalCollectionAmount;
  final double totalPenaltyCollected;
  final double totalBalancePrincipal;
  final double totalBalancePenalty;
  final int totalWeeksPaid;
  final int totalWeeksBalance;
  final int totalLoans;

  OutstandingSummary({
    required this.totalLoanAmount,
    required this.totalInterestAmount,
    required this.totalPenaltyAmount,
    required this.totalCollectionAmount,
    required this.totalPenaltyCollected,
    required this.totalBalancePrincipal,
    required this.totalBalancePenalty,
    required this.totalWeeksPaid,
    required this.totalWeeksBalance,
    required this.totalLoans,
  });
}