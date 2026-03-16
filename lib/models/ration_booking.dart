class RationBooking {
  final String id;
  final String userId;
  final String status;
  final DateTime bookingDate;
  final String title;

  RationBooking({
    required this.id,
    required this.userId,
    required this.status,
    required this.bookingDate,
    required this.title,
  });
}