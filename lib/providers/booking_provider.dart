import 'package:flutter/material.dart';

/// =============================
/// TIME SLOT MODEL
/// =============================
class TimeSlot {
  final String shortDisplayName;
  final IconData icon;

  const TimeSlot({
    required this.shortDisplayName,
    required this.icon,
  });
}

/// =============================
/// RATION BOOKING MODEL
/// =============================
class RationBooking {
  final String id;
  final String userId;
  final DateTime bookingDate;
  final String status;
  final TimeSlot timeSlot;

  RationBooking({
    required this.id,
    required this.userId,
    required this.bookingDate,
    required this.status,
    required this.timeSlot,
  });
}

/// =============================
/// BOOKING PROVIDER
/// =============================
class BookingProvider extends ChangeNotifier {

  /// PUBLIC LIST (REQUIRED BY UI)
  List<RationBooking> bookings = [];

  bool isLoading = false;

  /// =============================
  /// LOAD BOOKINGS (OFFLINE DEMO)
  /// =============================
  Future<void> loadUserBookings(String userId) async {

    try {
      isLoading = true;
      notifyListeners();

      /// simulate loading
      await Future.delayed(const Duration(milliseconds: 600));

      bookings = [
        RationBooking(
          id: "BK001",
          userId: userId,
          bookingDate:
              DateTime.now().subtract(const Duration(days: 3)),
          status: "completed",
          timeSlot: const TimeSlot(
            shortDisplayName: "Morning Slot",
            icon: Icons.wb_sunny,
          ),
        ),

        RationBooking(
          id: "BK002",
          userId: userId,
          bookingDate:
              DateTime.now().add(const Duration(days: 2)),
          status: "upcoming",
          timeSlot: const TimeSlot(
            shortDisplayName: "Afternoon Slot",
            icon: Icons.wb_cloudy,
          ),
        ),

        RationBooking(
          id: "BK003",
          userId: userId,
          bookingDate: DateTime.now(),
          status: "upcoming",
          timeSlot: const TimeSlot(
            shortDisplayName: "Evening Slot",
            icon: Icons.nightlight_round,
          ),
        ),
      ];

      isLoading = false;
      notifyListeners();

    } catch (e) {
      isLoading = false;
      notifyListeners();
    }
  }

  /// =============================
  /// REFRESH (USED BY SCREEN)
  /// =============================
  Future<void> refresh(String userId) async {
    await loadUserBookings(userId);
  }

  /// =============================
  /// ADD BOOKING
  /// =============================
  void addBooking(RationBooking booking) {
    bookings.add(booking);
    notifyListeners();
  }

  /// =============================
  /// CANCEL BOOKING
  /// =============================
  void cancelBooking(String id) {
    final index = bookings.indexWhere((b) => b.id == id);

    if (index != -1) {
      bookings[index] = RationBooking(
        id: bookings[index].id,
        userId: bookings[index].userId,
        bookingDate: bookings[index].bookingDate,
        status: "cancelled",
        timeSlot: bookings[index].timeSlot,
      );

      notifyListeners();
    }
  }
}