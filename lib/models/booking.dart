class Booking {
  final String id;
  final String userId;
  final String scheduleId;
  final String status;
  final double amount;
  final bool wasUsed;
  final DateTime createdAt;

  Booking({
    required this.id,
    required this.userId,
    required this.scheduleId,
    required this.status,
    required this.amount,
    required this.wasUsed,
    required this.createdAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      scheduleId: json['scheduleId'] ?? '',
      status: json['status'] ?? 'confirmed',
      amount: (json['amount'] ?? 0).toDouble(),
      wasUsed: json['wasUsed'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  bool get isConfirmed => status == 'confirmed';
  bool get isCancelled => status == 'cancelled';
  bool get isCompleted => status == 'completed';
}
