// lib/screens/reminder_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:finance_tracker/db/database_helper.dart';
import 'package:finance_tracker/models/reminder_model.dart'; // Ensure this model has NO completionDate
import 'package:finance_tracker/utils/colors.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Reminder> _displayedReminders = [];
  bool _isLoading = true;

  final _addReminderFormKey = GlobalKey<FormState>();
  final _personNameController = TextEditingController();
  final _amountController = TextEditingController();
  // These are used to hold state for the dialog when it's open
  String _dialogSelectedPaymentMethod = 'Cash';
  ReminderPartyType _dialogSelectedPartyType = ReminderPartyType.toGive;

  final List<String> _paymentMethodsOptions = ['Cash', 'bKash', 'Nagad', 'Card', 'Bank Transfer', 'Others'];

  @override
  void initState() {
    super.initState();
    _loadAndFilterReminders();
  }

  @override
  void dispose() {
    _personNameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadAndFilterReminders() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final allRemindersFromDb = await _dbHelper.getAllReminders();

    final now = DateTime.now();
    final oneWeekAgo = now.subtract(const Duration(days: 7));

    List<Reminder> filtered = allRemindersFromDb.where((reminder) {
      if (reminder.status == ReminderStatus.completed) {
        // Vanish if completed AND its dueDate is older than 1 week ago.
        bool shouldVanish = reminder.dueDate.isBefore(oneWeekAgo);
        return !shouldVanish;
      }
      return true; // Keep all pending reminders
    }).toList();

    filtered.sort((a, b) {
      if (a.status == ReminderStatus.pending && b.status == ReminderStatus.completed) return -1;
      if (a.status == ReminderStatus.completed && b.status == ReminderStatus.pending) return 1;
      if (a.isOverdue && !b.isOverdue) return -1;
      if (!a.isOverdue && b.isOverdue) return 1;
      return a.dueDate.compareTo(b.dueDate);
    });

    if (mounted) {
      setState(() {
        _displayedReminders = filtered;
        _isLoading = false;
      });
    }
  }

  void _showAddReminderDialog() {
    // Reset dialog-specific state variables before showing
    _personNameController.clear();
    _amountController.clear();
    _dialogSelectedPartyType = ReminderPartyType.toGive;
    _dialogSelectedPaymentMethod = 'Cash';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext bContext) {
        return StatefulBuilder(
            builder: (BuildContext modalContext, StateSetter setModalState) {
              return Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(modalContext).viewInsets.bottom,
                    left: 20, right: 20, top: 20
                ),
                child: Form(
                  key: _addReminderFormKey,
                  child: ListView(
                    shrinkWrap: true,
                    children: <Widget>[
                      Text('Add New Reminder',
                          style: Theme.of(modalContext).textTheme.titleLarge?.copyWith(fontSize: 22)),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _personNameController,
                        decoration: const InputDecoration(labelText: 'Name (Person/Entity)'),
                        validator: (value) => value == null || value.isEmpty ? 'Please enter a name' : null,
                      ),
                      const SizedBox(height: 16),
                      Text("Transaction Type:", style: Theme.of(modalContext).textTheme.titleMedium?.copyWith(fontSize: 16, color: AppColors.secondaryText)),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<ReminderPartyType>(
                              title: const Text('I will Pay / Give'),
                              value: ReminderPartyType.toGive,
                              groupValue: _dialogSelectedPartyType, // Use dialog state
                              onChanged: (ReminderPartyType? value) {
                                if (value != null) setModalState(() => _dialogSelectedPartyType = value);
                              },
                              activeColor: AppColors.accentGreen,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<ReminderPartyType>(
                              title: const Text('I will Receive'),
                              value: ReminderPartyType.toGet,
                              groupValue: _dialogSelectedPartyType, // Use dialog state
                              onChanged: (ReminderPartyType? value) {
                                if (value != null) setModalState(() => _dialogSelectedPartyType = value);
                              },
                              activeColor: AppColors.accentGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _amountController,
                        decoration: const InputDecoration(labelText: 'Amount', prefixText: '\$ '),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Enter an amount';
                          final double? amount = double.tryParse(value);
                          if (amount == null) return 'Invalid amount';
                          if (amount <= 0) return 'Amount must be positive';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _dialogSelectedPaymentMethod, // Use dialog state
                        decoration: const InputDecoration(labelText: 'Payment Method'),
                        items: _paymentMethodsOptions.map((String method) {
                          return DropdownMenuItem<String>(value: method, child: Text(method));
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) setModalState(() => _dialogSelectedPaymentMethod = newValue);
                        },
                        validator: (value) => value == null ? 'Select a payment method' : null,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        child: const Text('Add Reminder'),
                        onPressed: () async {
                          if (_addReminderFormKey.currentState?.validate() ?? false) {
                            double? amount = double.tryParse(_amountController.text);
                            if (amount == null) return; // Should be caught by validator

                            final newReminder = Reminder(
                              title: "${_dialogSelectedPartyType == ReminderPartyType.toGive ? "Pay to" : "Receive from"} ${_personNameController.text}",
                              personName: _personNameController.text,
                              partyType: _dialogSelectedPartyType,
                              amount: amount,
                              paymentMethod: _dialogSelectedPaymentMethod,
                              dueDate: DateTime.now(), // Simplified: Due date is now
                              status: ReminderStatus.pending,
                              // No notes or completionDate in this simplified creation
                            );

                            int id = await _dbHelper.insertReminder(newReminder);
                            if (id > 0) {
                              _loadAndFilterReminders();
                              if (Navigator.canPop(bContext)) {
                                Navigator.of(bContext).pop();
                              }
                            } else {
                              if (mounted){
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Failed to save reminder.'), backgroundColor: AppColors.expenseColor),
                                );
                              }
                            }
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              );
            }
        );
      },
    );
  }

  Future<void> _toggleReminderStatus(Reminder reminder) async {
    if (!mounted) return;
    ReminderStatus newStatus;
    if (reminder.status == ReminderStatus.pending) {
      newStatus = ReminderStatus.completed;
    } else {
      newStatus = ReminderStatus.pending;
    }

    final updatedReminder = Reminder(
      id: reminder.id,
      title: reminder.title,
      personName: reminder.personName,
      partyType: reminder.partyType,
      amount: reminder.amount,
      paymentMethod: reminder.paymentMethod,
      dueDate: reminder.dueDate,
      status: newStatus,
      notes: reminder.notes,
      // No completionDate field in this model version
    );
    await _dbHelper.updateReminder(updatedReminder);
    _loadAndFilterReminders();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment Reminders', style: theme.appBarTheme.titleTextStyle),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadAndFilterReminders,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentGreen))
          : _displayedReminders.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_paused_outlined, size: 80, color: AppColors.secondaryText.withOpacity(0.5)),
            const SizedBox(height: 20),
            Text('No active reminders!', style: theme.textTheme.titleLarge?.copyWith(color: AppColors.secondaryText)),
            const SizedBox(height: 8),
            Text('Tap "+" to add a new reminder.', style: theme.textTheme.bodyMedium),
          ],
        ),
      )
          : ListView.builder(
        itemCount: _displayedReminders.length,
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
        itemBuilder: (context, index) {
          final reminder = _displayedReminders[index];
          bool isCompleted = reminder.status == ReminderStatus.completed;
          bool isActuallyOverdue = reminder.isOverdue;

          Color tileColor = AppColors.cardBackground;
          Color textColor = AppColors.primaryText;
          TextDecoration textDecoration = TextDecoration.none;

          if (isCompleted) {
            tileColor = AppColors.cardBackground.withOpacity(0.7);
            textColor = AppColors.secondaryText.withOpacity(0.8);
            textDecoration = TextDecoration.lineThrough;
          } else if (isActuallyOverdue) {
            tileColor = AppColors.expenseColor.withOpacity(0.05);
          }

          IconData partyIcon = reminder.partyType == ReminderPartyType.toGive
              ? Icons.arrow_circle_up_rounded
              : Icons.arrow_circle_down_rounded;
          Color partyIconColor = reminder.partyType == ReminderPartyType.toGive
              ? AppColors.expenseColor
              : AppColors.incomeColor;

          return Card(
            elevation: isCompleted ? 0.5 : 1.5,
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            color: tileColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isActuallyOverdue && !isCompleted ? AppColors.expenseColor.withOpacity(0.4) : Colors.transparent,
                width: 1,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              leading: Checkbox(
                value: isCompleted,
                onChanged: (bool? value) {
                  _toggleReminderStatus(reminder);
                },
                activeColor: AppColors.accentGreen,
                checkColor: Colors.white,
                side: BorderSide(color: AppColors.secondaryText.withOpacity(0.5)),
              ),
              title: Text(
                  reminder.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: textDecoration,
                    color: textColor,
                  )
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${reminder.partyType == ReminderPartyType.toGive ? 'Pay to' : 'Receive from'} ${reminder.personName}",
                    style: TextStyle(decoration: textDecoration, color: textColor.withOpacity(isCompleted ? 0.8 : 1)),
                  ),
                  Text(
                    "Due: ${DateFormat('MMM dd, yy').format(reminder.dueDate)} (${reminder.paymentMethod})", // Kept yy for brevity
                    style: TextStyle(decoration: textDecoration, color: textColor.withOpacity(isCompleted ? 0.7 : 0.9), fontSize: 12),
                  ),
                  if (reminder.notes != null && reminder.notes!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text("Notes: ${reminder.notes}", style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: textColor.withOpacity(isCompleted ? 0.6 : 0.7)), maxLines: 1, overflow: TextOverflow.ellipsis,),
                    )
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(partyIcon, color: partyIconColor, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        NumberFormat.currency(locale: 'en_US', symbol: '\$').format(reminder.amount),
                        style: theme.textTheme.bodyLarge?.copyWith(
                            color: partyIconColor,
                            fontWeight: FontWeight.bold,
                            decoration: textDecoration,
                            fontSize: 15
                        ),
                      ),
                    ],
                  ),
                  if (isActuallyOverdue && !isCompleted)
                    Text("Overdue", style: theme.textTheme.bodySmall?.copyWith(color: AppColors.expenseColor, fontWeight: FontWeight.bold))
                  else if (!isCompleted)
                    Text("Pending", style: theme.textTheme.bodySmall?.copyWith(color: AppColors.secondaryText))
                  else
                    Text("Completed", style: theme.textTheme.bodySmall?.copyWith(color: AppColors.incomeColor)),
                ],
              ),
              isThreeLine: true,
              onLongPress: () async {
                final confirmDelete = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext dialogContext) => AlertDialog(
                    title: const Text('Delete Reminder?'),
                    content: Text('Are you sure you want to delete "${reminder.title}"?'),
                    actions: [
                      TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(dialogContext).pop(false)),
                      TextButton(child: const Text('Delete', style: TextStyle(color: AppColors.expenseColor)), onPressed: () => Navigator.of(dialogContext).pop(true)),
                    ],
                  ),
                );
                if (confirmDelete == true && mounted) {
                  await _dbHelper.deleteReminder(reminder.id!);
                  _loadAndFilterReminders();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reminder deleted.'), backgroundColor: AppColors.accentGreen),
                  );
                }
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddReminderDialog,
        tooltip: 'Add Reminder',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}