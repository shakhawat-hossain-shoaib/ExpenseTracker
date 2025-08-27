// lib/screens/add_transaction_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:finance_tracker/db/database_helper.dart';
import 'package:finance_tracker/models/transaction_model.dart' as app_models;
import 'package:finance_tracker/utils/colors.dart';

class AddTransactionScreen extends StatefulWidget {
  final app_models.Transaction? transactionToEdit;

  const AddTransactionScreen({super.key, this.transactionToEdit});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  late TextEditingController _amountController;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _dateController;

  app_models.TransactionType _selectedType = app_models.TransactionType.expense;
  DateTime _selectedDate = DateTime.now();
  String? _selectedCategory;

  final List<String> _incomeCategories = ['Salary', 'Freelance', 'Investment', 'Gifts', 'Other'];
  final List<String> _expenseCategories = ['Food', 'Bills', 'Shopping', 'Entertainment', 'Education', 'Transport', 'Health', 'Other'];
  List<String> _currentCategories = [];

  bool get _isEditing => widget.transactionToEdit != null;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _amountController = TextEditingController();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _dateController = TextEditingController(text: DateFormat('yyyy-MM-dd').format(_selectedDate));

    _currentCategories = _expenseCategories;
    if (_currentCategories.isNotEmpty) {
      _selectedCategory = _currentCategories[0];
    }

    if (_isEditing) {
      final transaction = widget.transactionToEdit!;
      _titleController.text = transaction.title;
      _amountController.text = transaction.amount.toStringAsFixed(2);
      _descriptionController.text = transaction.description ?? '';
      _selectedDate = transaction.date;
      _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
      _selectedType = transaction.type;
      _selectedCategory = transaction.category;
      _currentCategories = _selectedType == app_models.TransactionType.income
          ? _incomeCategories
          : _expenseCategories;
      if (!_currentCategories.contains(_selectedCategory) && _selectedCategory != null) {
        if (_currentCategories.isNotEmpty) {
          _selectedCategory = _currentCategories[0];
        } else {
          _selectedCategory = null;
        }
      }
    }

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onTypeChanged(app_models.TransactionType? type) {
    if (type != null) {
      setState(() {
        _selectedType = type;
        _currentCategories = type == app_models.TransactionType.income
            ? _incomeCategories
            : _expenseCategories;
        if (!_currentCategories.contains(_selectedCategory) || _currentCategories.isEmpty) {
          _selectedCategory = _currentCategories.isNotEmpty ? _currentCategories[0] : null;
        }
      });
    }
  }

  void _saveTransaction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategory == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please select a category.'),
              backgroundColor: Colors.orangeAccent,
              duration: Duration(seconds: 2)),
        );
      }
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final title = _isEditing ? (widget.transactionToEdit!.title.isNotEmpty ? widget.transactionToEdit!.title : _selectedCategory!) : _selectedCategory!;
    final description = _descriptionController.text;

    final transaction = app_models.Transaction(
      id: _isEditing ? widget.transactionToEdit!.id : null,
      title: title,
      amount: amount,
      date: _selectedDate,
      type: _selectedType,
      category: _selectedCategory!,
      description: description.isNotEmpty ? description : null,
    );

    if (_isEditing) {
      await _dbHelper.update(transaction);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Transaction updated! 🎉'),
              backgroundColor: AppColors.accentGreen,
              duration: Duration(seconds: 2)),
        );
      }
    } else {
      await _dbHelper.insert(transaction);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Transaction added! 💸'),
              backgroundColor: AppColors.accentGreen,
              duration: Duration(seconds: 2)),
        );
      }
    }
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Transaction' : 'Add transaction', style: theme.appBarTheme.titleTextStyle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: ScaleTransition(
        scale: _scaleAnimation,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20.0),
            children: <Widget>[
              Text('Amount', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.normal, color: AppColors.secondaryText)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                style: theme.textTheme.displaySmall?.copyWith(color: AppColors.primaryText, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                    prefixText: '\$ ',
                    prefixStyle: theme.textTheme.displaySmall?.copyWith(color: AppColors.primaryText, fontWeight: FontWeight.bold),
                    hintText: '0.00',
                    hintStyle: theme.textTheme.displaySmall?.copyWith(color: AppColors.secondaryText.withOpacity(0.5), fontWeight: FontWeight.bold),
                    filled: true,
                    fillColor: AppColors.cardBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16)
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter an amount';
                  if (double.tryParse(value) == null) return 'Enter a valid number';
                  if (double.parse(value) <= 0) return 'Amount must be positive';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _buildTypeSelector(theme),
              const SizedBox(height: 24),
              Text('Category', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.normal, color: AppColors.secondaryText)),
              const SizedBox(height: 8),
              _buildCategoryDropdown(theme),
              const SizedBox(height: 24),
              Text('Description (Optional)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.normal, color: AppColors.secondaryText)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  hintText: 'e.g., Lunch with colleagues',
                  fillColor: AppColors.cardBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(color: AppColors.accentGreen, width: 1.5),
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Cancel simply pops the screen
                },
                style: theme.outlinedButtonTheme.style, // Use theme style
                child: const Text('Cancel'), // UPDATED from 'Draft'
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _saveTransaction,
                style: theme.elevatedButtonTheme.style, // Use theme style
                child: Text(_isEditing ? 'Save Changes' : 'Add'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<app_models.TransactionType>(
        segments: <ButtonSegment<app_models.TransactionType>>[
          ButtonSegment<app_models.TransactionType>(
              value: app_models.TransactionType.income,
              label: Text('Income', style: TextStyle(color: _selectedType == app_models.TransactionType.income ? Colors.white: AppColors.primaryText)),
              icon: Icon(Icons.arrow_upward_rounded, color: _selectedType == app_models.TransactionType.income ? Colors.white: AppColors.incomeColor,)),
          ButtonSegment<app_models.TransactionType>(
              value: app_models.TransactionType.expense,
              label: Text('Expense', style: TextStyle(color: _selectedType == app_models.TransactionType.expense ? Colors.white: AppColors.primaryText)),
              icon: Icon(Icons.arrow_downward_rounded, color: _selectedType == app_models.TransactionType.expense ? Colors.white: AppColors.expenseColor,)),
        ],
        selected: <app_models.TransactionType>{_selectedType},
        onSelectionChanged: (Set<app_models.TransactionType> newSelection) {
          _onTypeChanged(newSelection.first);
        },
        style: SegmentedButton.styleFrom(
            backgroundColor: AppColors.cardBackground,
            foregroundColor: AppColors.primaryText,
            selectedForegroundColor: Colors.white,
            selectedBackgroundColor: _selectedType == app_models.TransactionType.income ? AppColors.incomeColor : AppColors.expenseColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            padding: const EdgeInsets.symmetric(vertical: 12)
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown(ThemeData theme) {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.cardBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: AppColors.accentGreen, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12)
      ),
      items: _currentCategories.map((String category) {
        return DropdownMenuItem<String>(
          value: category,
          child: Row(
            children: [
              Icon(app_models.categoryIcons[category] ?? Icons.circle_outlined, color: AppColors.secondaryText, size: 20),
              const SizedBox(width: 10),
              Text(category, style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.primaryText)),
            ],
          ),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedCategory = newValue;
        });
      },
      validator: (value) => value == null ? 'Please select a category' : null,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.secondaryText),
      dropdownColor: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(12),
    );
  }
}