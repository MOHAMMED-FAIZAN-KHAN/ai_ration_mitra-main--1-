import 'package:flutter/material.dart';

enum TimeSlot {
  morning,
  afternoon,
  evening,
}

extension TimeSlotExtension on TimeSlot {

  String get shortDisplayName {
    switch (this) {
      case TimeSlot.morning:
        return "Morning Slot";
      case TimeSlot.afternoon:
        return "Afternoon Slot";
      case TimeSlot.evening:
        return "Evening Slot";
    }
  }

  IconData get icon {
    switch (this) {
      case TimeSlot.morning:
        return Icons.wb_sunny;
      case TimeSlot.afternoon:
        return Icons.wb_cloudy;
      case TimeSlot.evening:
        return Icons.nightlight_round;
    }
  }

  String get value {
    return name;
  }

  static TimeSlot fromString(String value) {
    return TimeSlot.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TimeSlot.morning,
    );
  }
}