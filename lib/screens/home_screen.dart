// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:finance_tracker/db/database_helper.dart';
import 'package:finance_tracker/models/transaction_model.dart' as app_models;
import 'package:finance_tracker/utils/colors.dart';
import 'package:finance_tracker/screens/add_transaction_screen.dart';
import 'package:finance_tracker/widgets/transaction_item.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finance_tracker/utils/currency_manager.dart';


enum TransactionFilter { all, daily, weekly, monthly }

class HomeScreen extends StatefulWidget {
  final VoidCallback onNavigateToTransferTab; // Callback to switch to Transfer tab

  const HomeScreen({
    super.key,
    required this.onNavigateToTransferTab, // Require the callback
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<app_models.Transaction> _transactions = [];
  double _filteredIncome = 0.0;
  double _filteredExpense = 0.0;
  double _overallBalance = 0.0;
  bool _isLoading = true;
  TransactionFilter _selectedFilter = TransactionFilter.all;
  DateTime _currentDateContext = DateTime.now();
  String _userName = "User"; // Default name


  int _touchedIndexDonut = -1;

  @override
  void initState() {
    super.initState();
    _loadData();
    _checkUserName();
  }

  Future<void> _checkUserName() async {
    final prefs = await SharedPreferences.getInstance();
    String? name = prefs.getString('user_name');
    if (name == null || name.isEmpty) {
      // Name not set, show dialog
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showNameInputDialog();
      });
    } else {
      setState(() {
        _userName = name;
      });
    }
  }

  Future<void> _showNameInputDialog() async {
    TextEditingController nameController = TextEditingController();
    String tempCurrency = "USD";
    
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must enter a name
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Welcome!'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Please enter your name and currency.'),
                  const SizedBox(height: 15),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Your Name",
                      hintText: "e.g. Shoaib",
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 20),
                  const Text("Preferred Currency", style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: tempCurrency,
                        isExpanded: true,
                        items: ['USD', 'BDT', 'EUR', 'GBP', 'INR', 'AUD'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setStateDialog(() {
                            tempCurrency = newValue!;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                ElevatedButton(
                  child: const Text('Save'),
                  onPressed: () async {
                    if (nameController.text.trim().isNotEmpty) {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('user_name', nameController.text.trim());
                      await CurrencyManager().setCurrency(tempCurrency);
                      
                      if (mounted) {
                        setState(() {
                          _userName = nameController.text.trim();
                        });
                      }
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            );
          }
        );
      },
    );
  }

  // Public method for potential refresh from parent (MainAppScreen)
  void refreshData() {
    if (mounted) {
      print("HomeScreen: Data refresh triggered.");
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final allTimeIncome = await _dbHelper.getTotalIncome();
    final allTimeExpense = await _dbHelper.getTotalExpense();
    if (mounted) {
      setState(() {
        _overallBalance = allTimeIncome - allTimeExpense;
      });
    }

    DateTime startDate;
    DateTime endDate;

    switch (_selectedFilter) {
      case TransactionFilter.daily:
        startDate = DateTime(_currentDateContext.year, _currentDateContext.month, _currentDateContext.day);
        endDate = DateTime(_currentDateContext.year, _currentDateContext.month, _currentDateContext.day, 23, 59, 59);
        break;
      case TransactionFilter.weekly:
        DateTime firstDayOfWeek = _currentDateContext.subtract(Duration(days: _currentDateContext.weekday - 1));
        startDate = DateTime(firstDayOfWeek.year, firstDayOfWeek.month, firstDayOfWeek.day);
        endDate = startDate.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        break;
      case TransactionFilter.monthly:
        startDate = DateTime(_currentDateContext.year, _currentDateContext.month, 1);
        endDate = DateTime(_currentDateContext.year, _currentDateContext.month + 1, 0, 23, 59, 59);
        break;
      case TransactionFilter.all:
      default:
        startDate = DateTime(2000);
        endDate = DateTime(2200);
        break;
    }

    final transactionsForPeriod = (_selectedFilter == TransactionFilter.all)
        ? await _dbHelper.getAllTransactions()
        : await _dbHelper.getTransactionsByDateRange(startDate, endDate);

    double currentPeriodIncome = 0;
    double currentPeriodExpense = 0;
    for (var t in transactionsForPeriod) {
      if (t.type == app_models.TransactionType.income) {
        currentPeriodIncome += t.amount;
      } else {
        currentPeriodExpense += t.amount;
      }
    }

    List<app_models.Transaction> displayTransactionsInList = transactionsForPeriod;
    if (_selectedFilter == TransactionFilter.all && transactionsForPeriod.length > 7) {
      displayTransactionsInList = transactionsForPeriod.take(7).toList();
    }

    if (mounted) {
      setState(() {
        _transactions = displayTransactionsInList;
        _filteredIncome = currentPeriodIncome;
        _filteredExpense = currentPeriodExpense;
        _isLoading = false;
      });
    }
  }

  void _onFilterChanged(TransactionFilter filter) {
    if (!mounted) return;
    setState(() {
      _selectedFilter = filter;
      _currentDateContext = DateTime.now();
    });
    _loadData();
  }

  void _navigateToEditTransaction(app_models.Transaction transaction) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(transactionToEdit: transaction),
      ),
    );
    if (result == true && mounted) {
      _loadData();
    }
  }

  Future<bool?> _showDeleteConfirmationDialog(BuildContext context, int transactionId) async {
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
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showBuyMeCoffeeDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.local_cafe_rounded, color: AppColors.accentGreen, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Buy Me a Coffee'),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shakhawat Hossain Shoaib',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'I build things, break things, fix things, and somehow make it all work again. Most of my days disappear into code, robots, and random experiments that turn into projects. If you want to fuel the chaos—or just send a coffee my way—you\'ll find me here:',
                  style: TextStyle(height: 1.6),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.chipBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.accentGreen.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'bKash / Nagad / Upay / Pathao Pay',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(const ClipboardData(text: '01816487531')).then((_) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Number copied to clipboard!'),
                                duration: Duration(seconds: 2),
                                backgroundColor: AppColors.accentGreen,
                              ),
                            );
                          });
                        },
                        child: Text(
                          '01816487531',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.accentGreen,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close', style: TextStyle(color: AppColors.accentGreen)),
              onPressed: () => Navigator.of(dialogContext).pop(),
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
          body: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.accentGreen))
              : RefreshIndicator(
            onRefresh: _loadData,
            color: AppColors.accentGreen,
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: theme.scaffoldBackgroundColor,
                  elevation: 0,
                  pinned: false,
                  floating: true,
                  automaticallyImplyLeading: false,
                  expandedHeight: 90.0,
                  actions: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: IconButton(
                        icon: const Icon(Icons.local_cafe_rounded, color: AppColors.accentGreen),
                        onPressed: _showBuyMeCoffeeDialog,
                        tooltip: 'Buy me a coffee',
                      ),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    centerTitle: false,
                    title: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Hello,',
                          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.secondaryText, fontSize: 16),
                        ),
                        Text(
                          _userName,
                          style: theme.textTheme.titleLarge?.copyWith(fontSize: 26, height: 1.2),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: _buildCurrentBalanceCard(theme, currencyFormatter)),
                SliverToBoxAdapter(child: _buildFilterChips(theme)),
                SliverToBoxAdapter(child: _buildIncomeSpentSummaryCard(theme, currencyFormatter)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Recent transactions', style: theme.textTheme.titleMedium),
                        if (_transactions.isNotEmpty && (_transactions.length > 5 || _selectedFilter == TransactionFilter.all))
                          TextButton(
                            onPressed: () {
                              widget.onNavigateToTransferTab(); // Navigate to Transfer tab
                            },
                            child: Text('See All >', style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.accentGreen)),
                          ),
                      ],
                    ),
                  ),
                ),
                _buildRecentTransactionsList(symbol),
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrentBalanceCard(ThemeData theme, NumberFormat currencyFormatter) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      elevation: 0,
      color: AppColors.accentGreen,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentGreen.withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.account_balance_wallet_rounded, color: Colors.white.withOpacity(0.85), size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Current Balance',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                currencyFormatter.format(_overallBalance),
                style: theme.textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 40,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(ThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: TransactionFilter.values.map((filter) {
          bool isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(
                filter.toString().split('.').last[0].toUpperCase() + filter.toString().split('.').last.substring(1),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) _onFilterChanged(filter);
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

  Widget _buildIncomeSpentSummaryCard(ThemeData theme, NumberFormat currencyFormatter) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: AppColors.cardBackground,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIncomeExpenseRow(
                      icon: Icons.arrow_circle_up_rounded,
                      iconColor: AppColors.incomeColor,
                      label: 'Income',
                      amount: currencyFormatter.format(_filteredIncome),
                      amountColor: AppColors.incomeColor,
                      theme: theme,
                    ),
                    const SizedBox(height: 18),
                    _buildIncomeExpenseRow(
                      icon: Icons.arrow_circle_down_rounded,
                      iconColor: AppColors.expenseColor,
                      label: 'Spent',
                      amount: currencyFormatter.format(_filteredExpense),
                      amountColor: AppColors.expenseColor,
                      theme: theme,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 140,
                  child: _buildDonutChart(theme),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIncomeExpenseRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String amount,
    required Color amountColor,
    required ThemeData theme,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.secondaryText)),
            Text(amount, style: theme.textTheme.titleMedium?.copyWith(color: amountColor, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ],
    );
  }

  Widget _buildDonutChart(ThemeData theme) {
    final double totalForDonut = _filteredIncome + _filteredExpense;
    if (totalForDonut == 0) {
      return Center(
        child: Text('No data for chart', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.secondaryText)),
      );
    }

    List<PieChartSectionData> sections = [];
    if (_filteredIncome > 0) {
      sections.add(PieChartSectionData(
        color: AppColors.incomeColor, value: _filteredIncome, title: '',
        radius: _touchedIndexDonut == 0 ? 22 : 20,
        borderSide: _touchedIndexDonut == 0 ? BorderSide(color: AppColors.incomeColor.withOpacity(0.5), width: 2) : BorderSide.none,
      ));
    }
    if (_filteredExpense > 0) {
      int expenseSectionIndex = (_filteredIncome > 0) ? 1 : 0;
      sections.add(PieChartSectionData(
        color: AppColors.expenseColor, value: _filteredExpense, title: '',
        radius: _touchedIndexDonut == expenseSectionIndex ? 22 : 20,
        borderSide: _touchedIndexDonut == expenseSectionIndex ? BorderSide(color: AppColors.expenseColor.withOpacity(0.5), width: 2) : BorderSide.none,
      ));
    }
    if (sections.isEmpty) {
      return Center(
        child: Text('No data for chart', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.secondaryText)),
      );
    }

    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            if (!mounted) return;
            setState(() {
              if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                _touchedIndexDonut = -1; return;
              }
              _touchedIndexDonut = pieTouchResponse.touchedSection!.touchedSectionIndex;
            });
          },
        ),
        sectionsSpace: 2, centerSpaceRadius: 35, sections: sections, startDegreeOffset: -90,
      ),
      swapAnimationDuration: const Duration(milliseconds: 250),
      swapAnimationCurve: Curves.easeInOut,
    );
  }

  Widget _buildRecentTransactionsList(String currencySymbol) {
    if (_transactions.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          height: 150, alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long_outlined, size: 50, color: AppColors.secondaryText.withOpacity(0.4)),
              const SizedBox(height: 10),
              Text('No transactions for this period.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.secondaryText)),
            ],
          ),
        ),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final transaction = _transactions[index];
          return TransactionItem(
            transaction: transaction,
            currencySymbol: currencySymbol,
            onTap: () {
              widget.onNavigateToTransferTab(); // Navigate to Transfer tab
              // If you want to pass the specific transaction to TransferScreen,
              // you'll need to modify TransferScreen to accept it and update MainAppScreen's navigation logic.
            },
            onDelete: () async {
              final confirm = await _showDeleteConfirmationDialog(context, transaction.id!);
              if (confirm == true && mounted) {
                await _dbHelper.delete(transaction.id!);
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Transaction deleted!'), backgroundColor: AppColors.expenseColor),
                );
              }
            },
          );
        },
        childCount: _transactions.length,
      ),
    );
  }
}