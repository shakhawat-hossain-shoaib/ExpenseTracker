// lib/models/transaction_model.dart
import 'package:flutter/material.dart';

enum TransactionType { income, expense }

final Map<String, IconData> categoryIcons = {
  'Food': Icons.restaurant_menu_rounded,
  'Bills': Icons.receipt_long_rounded,
  'Shopping': Icons.shopping_bag_rounded,
  'Entertainment': Icons.movie_filter_rounded,
  'Education': Icons.school_rounded,
  'Transport': Icons.directions_car_rounded,
  'Salary': Icons.account_balance_wallet_rounded,
  'Freelance': Icons.work_outline_rounded,
  'Investment': Icons.trending_up_rounded,
  'Gifts': Icons.card_giftcard_rounded,
  'Health': Icons.local_hospital_rounded,
  'Other': Icons.more_horiz_rounded,
};

class Transaction {
  final int? id;
  final String title;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final String category;
  // final String paymentType; // REMOVED
  final String? description;

  Transaction({
    this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
    required this.category,
    // required this.paymentType, // REMOVED
    this.description,
  });

  IconData get categoryIcon => categoryIcons[category] ?? Icons.category_rounded;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': type.toString(),
      'category': category,
      // 'paymentType': paymentType, // REMOVED
      'description': description,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      title: map['title'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      type: TransactionType.values.firstWhere((e) => e.toString() == map['type']),
      category: map['category'],
      // paymentType: map['paymentType'] ?? 'Unknown', // REMOVED
      description: map['description'],
    );
  }
}