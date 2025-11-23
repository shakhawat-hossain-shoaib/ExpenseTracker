// lib/screens/analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:finance_tracker/db/database_helper.dart';
import 'package:finance_tracker/models/transaction_model.dart' as app_models;
import 'package:finance_tracker/utils/colors.dart';
import 'package:finance_tracker/widgets/transaction_item.dart';
import 'package:finance_tracker/screens/add_transaction_screen.dart';
import 'package:finance_tracker/utils/currency_manager.dart';

// Enum for filtering transactions in the history section
enum HistoryFilter { daily, weekly, monthly }

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // For Daily Analytics Pie Chart (Today's summary)
  double _todayIncome = 0.0;
  double _todayExpense = 0.0;
  bool _isLoadingDailyPie = true;
  int _touchedIndexDailyPie = -1;

  // For Transaction History List
  List<app_models.Transaction> _historyTransactions = [];
  bool _isLoadingHistory = true;
  HistoryFilter _selectedHistoryFilter = HistoryFilter.monthly; // Default to monthly
  DateTime _contextDateForHistory = DateTime.now(); // Context date for filters

  @override
  void initState() {
    super.initState();
    _loadDailyPieChartData();
    _loadHistoryTransactions();
  }

  Future<void> _loadDailyPieChartData() async {
    if (!mounted) return;
    setState(() => _isLoadingDailyPie = true);
    DateTime today = DateTime.now();
    DateTime startOfToday = DateTime(today.year, today.month, today.day);
    DateTime endOfToday = DateTime(today.year, today.month, today.day, 23, 59, 59);

    final income = await _dbHelper.getTotalIncome(startDate: startOfToday, endDate: endOfToday);
    final expense = await _dbHelper.getTotalExpense(startDate: startOfToday, endDate: endOfToday);

    if (mounted) {
      setState(() {
        _todayIncome = income;
        _todayExpense = expense;
        _isLoadingDailyPie = false;
      });
    }
  }

  Future<void> _loadHistoryTransactions() async {
    if (!mounted) return;
    setState(() => _isLoadingHistory = true);

    DateTime startDate;
    DateTime endDate;

    switch (_selectedHistoryFilter) {
      case HistoryFilter.daily:
        startDate = DateTime(_contextDateForHistory.year, _contextDateForHistory.month, _contextDateForHistory.day);
        endDate = DateTime(_contextDateForHistory.year, _contextDateForHistory.month, _contextDateForHistory.day, 23, 59, 59);
        break;
      case HistoryFilter.weekly:
        DateTime firstDayOfWeek = _contextDateForHistory.subtract(Duration(days: _contextDateForHistory.weekday - 1));
        startDate = DateTime(firstDayOfWeek.year, firstDayOfWeek.month, firstDayOfWeek.day);
        endDate = startDate.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        break;
      case HistoryFilter.monthly:
      default: // Default to monthly
        startDate = DateTime(_contextDateForHistory.year, _contextDateForHistory.month, 1);
        endDate = DateTime(_contextDateForHistory.year, _contextDateForHistory.month + 1, 0, 23, 59, 59);
        break;
    }
    final transactions = await _dbHelper.getTransactionsByDateRange(startDate, endDate);
    if (mounted) {
      setState(() {
        _historyTransactions = transactions;
        _isLoadingHistory = false;
      });
    }
  }

  Future<void> _pickDateForHistoryContext(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _contextDateForHistory,
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 5),
      helpText: 'SELECT CONTEXT DATE',
      builder: (context, child) {
        return Theme(
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
    if (picked != null && picked != _contextDateForHistory) {
      if (mounted) {
        setState(() {
          _contextDateForHistory = picked;
        });
        _loadHistoryTransactions(); // Reload history with new context date
      }
    }
  }

  void _onHistoryFilterChanged(HistoryFilter filter) {
    if (!mounted) return;
    setState(() {
      _selectedHistoryFilter = filter;
      // _contextDateForHistory remains the same unless user picks a new one
    });
    _loadHistoryTransactions();
  }

  void _navigateToEditTransaction(app_models.Transaction transaction) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(transactionToEdit: transaction),
      ),
    );
    if (result == true && mounted) {
      _loadDailyPieChartData();
      _loadHistoryTransactions();
    }
  }

  Future<bool?> _showDeleteConfirmationDialog(BuildContext context, int transactionId, Function onConfirm) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this transaction? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: AppColors.secondaryText)),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
                child: const Text('Delete', style: TextStyle(color: AppColors.expenseColor)),
                onPressed: () {
                  Navigator.of(dialogContext).pop(true);
                  onConfirm();
                }
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<String>(
      valueListenable: CurrencyManager().currencyNotifier,
      builder: (context, currencyCode, child) {
        final symbol = CurrencyManager.getSymbolForCurrency(currencyCode);
        final NumberFormat currencyFormatter = NumberFormat.currency(locale: 'en_US', symbol: symbol);

        return Scaffold(
          appBar: AppBar(
            title: Text('Analytics & History', style: theme.appBarTheme.titleTextStyle),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: (){
                  _loadDailyPieChartData();
                  _loadHistoryTransactions();
                },
                tooltip: 'Refresh All Data',
              )
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await _loadDailyPieChartData();
              await _loadHistoryTransactions();
            },
            color: AppColors.accentGreen,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // --- Daily Analytics Pie Chart Section ---
                Text(
                  'Today\'s Financial Flow (${DateFormat('MMM dd').format(DateTime.now())})',
                  style: theme.textTheme.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                _isLoadingDailyPie
                    ? const Center(heightFactor: 3, child: CircularProgressIndicator(color: AppColors.accentGreen))
                    : _buildDailyPieChartContent(theme, currencyFormatter),

                const SizedBox(height: 24),
                const Divider(thickness: 1.5, height: 32),
                const SizedBox(height: 16),

                // --- Transaction History Section ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Transaction History',
                      style: theme.textTheme.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.calendar_month_outlined, size: 20, color: AppColors.accentGreen),
                      label: Text(
                        _selectedHistoryFilter == HistoryFilter.daily ? DateFormat('MMM dd, yy').format(_contextDateForHistory) :
                        _selectedHistoryFilter == HistoryFilter.weekly ? "Week of ${DateFormat('MMM dd').format(_contextDateForHistory.subtract(Duration(days: _contextDateForHistory.weekday - 1)))}" :
                        DateFormat('MMMM yyyy').format(_contextDateForHistory),
                        style: const TextStyle(color: AppColors.accentGreen),
                      ),
                      onPressed: () => _pickDateForHistoryContext(context),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                _buildHistoryFilterChips(theme),
                const SizedBox(height: 16),
                _isLoadingHistory
                    ? const Center(heightFactor: 3, child: CircularProgressIndicator(color: AppColors.accentGreen))
                    : _buildHistoryListContent(theme, symbol),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDailyPieChartContent(ThemeData theme, NumberFormat currencyFormatter) {
    final double totalToday = _todayIncome + _todayExpense;
    if (totalToday == 0 && !_isLoadingDailyPie) {
      return Center( /* ... No data message as before ... */
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30.0),
          child: Column(
            children: [
              Icon(Icons.pie_chart_outline_rounded, size: 50, color: AppColors.secondaryText.withOpacity(0.5)),
              const SizedBox(height: 10),
              Text('No income or expenses for today.', style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.secondaryText)),
            ],
          ),
        ),
      );
    }
    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  if (!mounted) return;
                  setState(() {
                    if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                      _touchedIndexDailyPie = -1; return;
                    }
                    _touchedIndexDailyPie = pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 3,
              centerSpaceRadius: 60,
              sections: [
                if (_todayIncome > 0)
                  PieChartSectionData(
                    color: AppColors.incomeColor, value: _todayIncome,
                    title: '${(_todayIncome / totalToday * 100).toStringAsFixed(0)}%',
                    radius: _touchedIndexDailyPie == 0 ? 60 : 50,
                    titleStyle: TextStyle(fontSize: _touchedIndexDailyPie == 0 ? 16 : 12, fontWeight: FontWeight.bold, color: Colors.white, shadows: const [Shadow(color: Colors.black38, blurRadius: 2)]),
                  ),
                if (_todayExpense > 0)
                  PieChartSectionData(
                    color: AppColors.expenseColor, value: _todayExpense,
                    title: '${(_todayExpense / totalToday * 100).toStringAsFixed(0)}%',
                    radius: (_todayIncome > 0 && _touchedIndexDailyPie == 1) || (_todayIncome == 0 && _touchedIndexDailyPie == 0) ? 60 : 50,
                    titleStyle: TextStyle(fontSize: (_todayIncome > 0 && _touchedIndexDailyPie == 1) || (_todayIncome == 0 && _touchedIndexDailyPie == 0) ? 16 : 12, fontWeight: FontWeight.bold, color: Colors.white, shadows: const [Shadow(color: Colors.black38, blurRadius: 2)]),
                  ),
              ],
            ),
            swapAnimationDuration: const Duration(milliseconds: 250),
          ),
        ),
        const SizedBox(height: 20),
        _buildLegendItem(AppColors.incomeColor, 'Today\'s Income', currencyFormatter.format(_todayIncome), theme),
        const SizedBox(height: 8),
        _buildLegendItem(AppColors.expenseColor, 'Today\'s Expense', currencyFormatter.format(_todayExpense), theme),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String title, String amount, ThemeData theme) {
    return Row( /* ... As before ... */
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          width: 14, height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Text('$title:', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.normal, color: AppColors.secondaryText)),
        const Spacer(),
        Text(amount, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, color: AppColors.primaryText)),
      ],
    );
  }

  Widget _buildHistoryFilterChips(ThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: HistoryFilter.values.map((filter) {
          bool isSelected = _selectedHistoryFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(
                filter.toString().split('.').last[0].toUpperCase() + filter.toString().split('.').last.substring(1),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) _onHistoryFilterChanged(filter);
              },
              backgroundColor: AppColors.cardBackground,
              selectedColor: AppColors.chipBackground,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.accentGreen : AppColors.secondaryText,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
                side: BorderSide(color: isSelected ? AppColors.accentGreen.withOpacity(0.5) : AppColors.lightGrey.withOpacity(0.7)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHistoryListContent(ThemeData theme, String currencySymbol) {
    if (_historyTransactions.isEmpty && !_isLoadingHistory) {
      return Center( /* ... No data message as before ... */
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30.0),
          child: Column(
            children: [
              Icon(Icons.hourglass_empty_rounded, size: 50, color: AppColors.secondaryText.withOpacity(0.5)),
              const SizedBox(height: 10),
              Text('No transactions for the selected period.',
                style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.secondaryText),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _historyTransactions.length,
      itemBuilder: (context, index) {
        final transaction = _historyTransactions[index];
        return TransactionItem(
          transaction: transaction,
          currencySymbol: currencySymbol,
          onTap: () => _navigateToEditTransaction(transaction),
          onDelete: () async {
            await _showDeleteConfirmationDialog(context, transaction.id!, () async {
              if (mounted) {
                await _dbHelper.delete(transaction.id!);
                _loadHistoryTransactions();
                _loadDailyPieChartData(); // If deleted transaction was from today
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Transaction deleted!'), backgroundColor: AppColors.expenseColor),
                );
              }
            });
          },
        );
      },
    );
  }
}