// lib/screens/transfer_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:finance_tracker/db/database_helper.dart';
import 'package:finance_tracker/models/transaction_model.dart' as app_models;
import 'package:finance_tracker/widgets/transaction_item.dart'; // Assuming this is updated
import 'package:finance_tracker/utils/colors.dart';
import 'package:finance_tracker/screens/add_transaction_screen.dart';


class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<app_models.Transaction> _todayTransactions = [];
  double _todayIncome = 0.0;
  double _todayExpense = 0.0;
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now(); // For fetching today's transactions

  @override
  void initState() {
    super.initState();
    _loadDailyData();
  }

  Future<void> _loadDailyData() async {
    setState(() => _isLoading = true);
    final transactions = await _dbHelper.getTransactionsForDay(_selectedDate);

    double income = 0;
    double expense = 0;
    for (var t in transactions) {
      if (t.type == app_models.TransactionType.income) {
        income += t.amount;
      } else {
        expense += t.amount;
      }
    }

    setState(() {
      _todayTransactions = transactions;
      _todayIncome = income;
      _todayExpense = expense;
      _isLoading = false;
    });
  }

  void _navigateToEditTransaction(app_models.Transaction transaction) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(transactionToEdit: transaction),
      ),
    );
    if (result == true) {
      _loadDailyData(); // Reload data if a transaction was updated
    }
  }

  Future<bool?> _showDeleteConfirmationDialog(BuildContext context, int transactionId) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this transaction? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: AppColors.secondaryText)),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: AppColors.expenseColor)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final NumberFormat currencyFormatter = NumberFormat.currency(locale: 'en_US', symbol: '\$');

    return Scaffold(
      appBar: AppBar(
        title: Text('Daily Summary - ${DateFormat('MMM dd, yyyy').format(_selectedDate)}'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadDailyData,
            tooltip: 'Refresh Data',
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentGreen))
          : RefreshIndicator(
        onRefresh: _loadDailyData,
        color: AppColors.accentGreen,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryChip(
                    label: 'Income',
                    amount: currencyFormatter.format(_todayIncome),
                    color: AppColors.incomeColor,
                    context: context,
                  ),
                  _buildSummaryChip(
                    label: 'Expense',
                    amount: currencyFormatter.format(_todayExpense),
                    color: AppColors.expenseColor,
                    context: context,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            Expanded(
              child: _todayTransactions.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 60, color: AppColors.secondaryText.withOpacity(0.5)),
                    const SizedBox(height: 10),
                    Text('No transactions for today.', style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.secondaryText)),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.only(bottom: 80), // Space for potential FAB if screen had one
                itemCount: _todayTransactions.length,
                itemBuilder: (context, index) {
                  final transaction = _todayTransactions[index];
                  return TransactionItem( // Ensure TransactionItem is updated
                    transaction: transaction,
                    onTap: () => _navigateToEditTransaction(transaction),
                    onDelete: () async {
                      final confirm = await _showDeleteConfirmationDialog(context, transaction.id!);
                      if (confirm == true) {
                        await _dbHelper.delete(transaction.id!);
                        _loadDailyData();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Transaction deleted!'), backgroundColor: AppColors.expenseColor),
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryChip({
    required String label,
    required String amount,
    required Color color,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    return Chip(
      backgroundColor: color.withOpacity(0.15),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      label: RichText(
        text: TextSpan(
          style: theme.textTheme.bodyMedium?.copyWith(color: color),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.normal)),
            TextSpan(text: amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}