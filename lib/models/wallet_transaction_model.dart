class WalletTransaction {
  final String id, user, currency, status, type;
  final int amount;
  final DateTime date;

  WalletTransaction({
    required this.id,
    required this.user,
    required this.currency,
    required this.status,
    required this.type,
    required this.amount,
    required this.date,
  });

  factory WalletTransaction.fromMap(Map<String, dynamic> data) {
    return WalletTransaction(
      id: data['id'],
      user: data['user'],
      currency: data['currency'],
      status: data['status'],
      type: data['type'],
      amount: data['amount'],
      date: data['date'].toDate(),
    );
  }
}
