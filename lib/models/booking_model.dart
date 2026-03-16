// lib/models/booking_model.dart
import 'package:flutter/material.dart';
enum TimeSlot {
  morning,
  afternoon,
  evening
}

class BookingModel {
  final String id;
  final String userId;
  final String userName;
  final DateTime bookingDate;
  final TimeSlot timeSlot;
  final String status; // pending, confirmed, completed, cancelled
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? notes;

  BookingModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.bookingDate,
    required this.timeSlot,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.notes,
  });

  // Copy with method for updating
  BookingModel copyWith({
    String? id,
    String? userId,
    String? userName,
    DateTime? bookingDate,
    TimeSlot? timeSlot,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
  }) {
    return BookingModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      bookingDate: bookingDate ?? this.bookingDate,
      timeSlot: timeSlot ?? this.timeSlot,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
    );
  }

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'bookingDate': bookingDate.toIso8601String(),
      'timeSlot': timeSlot.index,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'notes': notes,
    };
  }

  // Create from Map
  factory BookingModel.fromMap(Map<String, dynamic> map) {
    return BookingModel(
      id: map['id'],
      userId: map['userId'],
      userName: map['userName'],
      bookingDate: DateTime.parse(map['bookingDate']),
      timeSlot: TimeSlot.values[map['timeSlot']],
      status: map['status'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      notes: map['notes'],
    );
  }

  // Helper method to check if booking is upcoming
  bool get isUpcoming {
    final now = DateTime.now();
    return bookingDate.isAfter(now) && 
           status != 'cancelled' && 
           status != 'completed';
  }

  // Helper method to check if booking is past
  bool get isPast {
    final now = DateTime.now();
    return bookingDate.isBefore(now) || 
           status == 'completed' || 
           status == 'cancelled';
  }

  // Get days remaining until booking
  int get daysRemaining {
    final now = DateTime.now();
    return bookingDate.difference(now).inDays;
  }

  // Get formatted time slot string
  String get timeSlotFormatted {
    switch (timeSlot) {
      case TimeSlot.morning:
        return 'Morning (8:00 AM - 12:00 PM)';
      case TimeSlot.afternoon:
        return 'Afternoon (12:00 PM - 4:00 PM)';
      case TimeSlot.evening:
        return 'Evening (4:00 PM - 6:00 PM)';
    }
  }

  // Get short time slot label
  String get timeSlotShort {
    switch (timeSlot) {
      case TimeSlot.morning:
        return 'M';
      case TimeSlot.afternoon:
        return 'A';
      case TimeSlot.evening:
        return 'E';
    }
  }

  // Get status color
  Color getStatusColor() {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}