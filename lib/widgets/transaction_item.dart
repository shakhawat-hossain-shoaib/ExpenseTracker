// lib/widgets/transaction_item.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:finance_tracker/models/transaction_model.dart' as app_models;
import 'package:finance_tracker/utils/colors.dart';

class TransactionItem extends StatelessWidget {
  final app_models.Transaction transaction;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  const TransactionItem({
    super.key,
    required this.transaction,
    required this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final NumberFormat currencyFormatter = NumberFormat.currency(locale: 'en_US', symbol: '\$');
    final DateFormat dateFormatter = DateFormat('MMM dd, yyyy');
    final bool isIncome = transaction.type == app_models.TransactionType.income;
    final Color amountColor = isIncome ? AppColors.incomeColor : AppColors.primaryText;
    final IconData categoryIcon = transaction.categoryIcon;

    return Slidable(
      key: ValueKey(transaction.id),
      endActionPane: ActionPane( /* ... As before ... */
        motion: const BehindMotion(),
        children: [
          SlidableAction(
            onPressed: (context) => onDelete(),
            backgroundColor: AppColors.expenseColor,
            foregroundColor: Colors.white,
            icon: Icons.delete_outline_rounded,
            label: 'Delete',
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
      child: Card(
        elevation: 0.5,
        color: AppColors.cardBackground,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: AppColors.accentGreen.withOpacity(0.1),
          highlightColor: AppColors.accentGreen.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.chipBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(categoryIcon, color: AppColors.primaryText.withOpacity(0.7), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.category,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: AppColors.primaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        // Display description or 'No details'
                        transaction.description?.isNotEmpty == true ? transaction.description! : 'No details',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.secondaryText,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column( /* ... Amount and Date as before ... */
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${isIncome ? '+' : '-'} ${currencyFormatter.format(transaction.amount)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: amountColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateFormatter.format(transaction.date),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}