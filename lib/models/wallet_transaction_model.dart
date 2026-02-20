DateTime _parseDate(dynamic v) {
  if (v == null) return DateTime.now();
  if (v is DateTime) return v;
  if (v is Map && v['_seconds'] != null) return DateTime.fromMillisecondsSinceEpoch((v['_seconds'] as int) * 1000);
  if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
  return DateTime.now();
}

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
      id: data['id']?.toString() ?? '',
      user: data['user']?.toString() ?? '',
      currency: data['currency']?.toString() ?? '',
      status: data['status']?.toString() ?? '',
      type: data['type']?.toString() ?? '',
      amount: (data['amount'] as num?)?.toInt() ?? 0,
      date: _parseDate(data['date']),
    );
  }
}

