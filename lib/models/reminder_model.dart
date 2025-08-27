// lib/models/reminder_model.dart

enum ReminderPartyType { toGive, toGet }
enum ReminderStatus { pending, completed }

class Reminder {
  final int? id;
  final String title;
  final String personName;
  final ReminderPartyType partyType;
  final double amount;
  final String paymentMethod;
  final DateTime dueDate;
  final ReminderStatus status;
  final String? notes;
  // NO completionDate field here

  Reminder({
    this.id,
    required this.title,
    required this.personName,
    required this.partyType,
    required this.amount,
    required this.paymentMethod,
    required this.dueDate,
    this.status = ReminderStatus.pending,
    this.notes,
  });

  bool get isOverdue {
    return status != ReminderStatus.completed &&
        dueDate.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'personName': personName,
      'partyType': partyType.toString(),
      'amount': amount,
      'paymentMethod': paymentMethod,
      'dueDate': dueDate.toIso8601String(),
      'status': status.toString(),
      'notes': notes,
      // NO completionDate in the map
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'],
      title: map['title'],
      personName: map['personName'],
      partyType: ReminderPartyType.values.firstWhere(
              (e) => e.toString() == map['partyType'],
          orElse: () => ReminderPartyType.toGive
      ),
      amount: map['amount'] as double, // Ensure correct type casting
      paymentMethod: map['paymentMethod'],
      dueDate: DateTime.parse(map['dueDate']),
      status: ReminderStatus.values.firstWhere(
              (e) => e.toString() == map['status'],
          orElse: () => ReminderStatus.pending
      ),
      notes: map['notes'],
      // NO completionDate when creating from map
    );
  }
}