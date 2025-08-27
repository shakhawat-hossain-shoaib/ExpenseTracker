// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:finance_tracker/db/database_helper.dart';
import 'package:finance_tracker/models/transaction_model.dart' as app_models;
import 'package:finance_tracker/widgets/transaction_item.dart';
import 'package:finance_tracker/utils/colors.dart';
import 'package:finance_tracker/screens/add_transaction_screen.dart';


class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<app_models.Transaction> _monthlyTransactions = [];
  bool _isLoading = true;
  DateTime _selectedMonth = DateTime.now(); // Default to current month

  @override
  void initState() {
    super.initState();
    _loadMonthlyData();
  }

  Future<void> _loadMonthlyData() async {
    setState(() => _isLoading = true);
    final transactions = await _dbHelper.getTransactionsForMonth(
        _selectedMonth.year, _selectedMonth.month);
    setState(() {
      _monthlyTransactions = transactions;
      _isLoading = false;
    });
  }

  Future<void> _pickMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 5), // Allow future years for planning if needed
      initialDatePickerMode: DatePickerMode.year, // Start with year selection
      helpText: 'SELECT MONTH & YEAR',
      builder: (context, child) {
        return Theme( // Apply custom theme to date picker
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.accentGreen,
              onPrimary: Colors.white,
              onSurface: AppColors.primaryText,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColors.accentGreen),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && (picked.year != _selectedMonth.year || picked.month != _selectedMonth.month)) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
      });
      _loadMonthlyData();
    }
  }

  void _navigateToEditTransaction(app_models.Transaction transaction) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(transactionToEdit: transaction),
      ),
    );
    if (result == true) {
      _loadMonthlyData();
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Monthly History - ${DateFormat('MMMM yyyy').format(_selectedMonth)}'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            onPressed: () => _pickMonth(context),
            tooltip: 'Select Month',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadMonthlyData,
            tooltip: 'Refresh Data',
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentGreen))
          : RefreshIndicator(
        onRefresh: _loadMonthlyData,
        color: AppColors.accentGreen,
        child: _monthlyTransactions.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.hourglass_empty_rounded, size: 60, color: AppColors.secondaryText.withOpacity(0.5)),
              const SizedBox(height: 10),
              Text('No transactions for ${DateFormat('MMMM yyyy').format(_selectedMonth)}.',
                style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.secondaryText),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: _monthlyTransactions.length,
          itemBuilder: (context, index) {
            final transaction = _monthlyTransactions[index];
            return TransactionItem(
              transaction: transaction,
              onTap: () => _navigateToEditTransaction(transaction),
              onDelete: () async {
                final confirm = await _showDeleteConfirmationDialog(context, transaction.id!);
                if (confirm == true) {
                  await _dbHelper.delete(transaction.id!);
                  _loadMonthlyData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Transaction deleted!'), backgroundColor: AppColors.expenseColor),
                  );
                }
              },
            );
          },
        ),
      ),
    );
  }
}