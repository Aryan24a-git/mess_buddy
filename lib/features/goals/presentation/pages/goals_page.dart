import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../providers/goals_provider.dart';
import '../../domain/models/goal.dart';
import 'package:intl/intl.dart';
import '../../../monetization/presentation/providers/monetization_provider.dart';

// Selection state provider
final selectedGoalsProvider = StateProvider<Set<int>>((ref) => {});

class GoalsPage extends ConsumerWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsState = ref.watch(goalsProvider);
    final selectedIds = ref.watch(selectedGoalsProvider);
    final isSelectionMode = selectedIds.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: isSelectionMode 
          ? IconButton(
              icon: const Icon(Icons.close, color: AppColors.textPrimary),
              onPressed: () => ref.read(selectedGoalsProvider.notifier).state = {},
            )
          : null,
        title: Text(
          isSelectionMode ? '${selectedIds.length} Selected' : 'Savings Goals',
          style: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          if (isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: () => _confirmDelete(context, ref, selectedIds.toList()),
            ),
        ],
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: goalsState.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
          data: (goals) {
            if (goals.isEmpty) {
              return _buildEmptyState();
            }
            return ListView.separated(
              padding: const EdgeInsets.all(AppDimensions.pNormal),
              itemCount: goals.length,
              separatorBuilder: (context, index) => const SizedBox(height: AppDimensions.s3),
              itemBuilder: (context, index) {
                final goal = goals[index];
                final isSelected = selectedIds.contains(goal.id);

                return GestureDetector(
                  onLongPress: () {
                    if (goal.id != null) {
                      ref.read(selectedGoalsProvider.notifier).update((state) => {...state, goal.id!});
                    }
                  },
                  onTap: () {
                    if (isSelectionMode && goal.id != null) {
                       ref.read(selectedGoalsProvider.notifier).update((state) {
                         final newState = Set<int>.from(state);
                         if (newState.contains(goal.id)) {
                           newState.remove(goal.id);
                         } else {
                           newState.add(goal.id!);
                         }
                         return newState;
                       });
                    }
                  },
                  child: Stack(
                    children: [
                      _buildGoalCard(goal, context, ref),
                      if (isSelected)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppDimensions.r3),
                              border: Border.all(color: AppColors.primary, width: 2),
                            ),
                            child: const Center(
                              child: Icon(Icons.check_circle, color: AppColors.primary, size: 32),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: !isSelectionMode 
        ? FloatingActionButton.extended(
            onPressed: () {
              if (!ref.read(monetizationProvider).isPro) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Savings Goals are a PRO feature. Upgrade to unlock!')),
                );
                return;
              }
              _showAddGoalSheet(context, ref);
            },
            backgroundColor: ref.watch(monetizationProvider).isPro ? AppColors.accent : AppColors.textMuted,
            icon: Icon(
              ref.watch(monetizationProvider).isPro ? Icons.add_task : Icons.lock_outline, 
              color: AppColors.textPrimary
            ),
            label: Text(
              ref.watch(monetizationProvider).isPro ? 'New Goal' : 'Unlock Pro', 
              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)
            ),
          )
        : null,
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, List<int> ids) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Goals?', style: TextStyle(color: AppColors.textPrimary)),
        content: Text('Are you sure you want to remove ${ids.length} savings goals?', style: const TextStyle(color: AppColors.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              for (final id in ids) {
                await ref.read(goalsProvider.notifier).deleteGoal(id);
              }
              ref.read(selectedGoalsProvider.notifier).state = {};
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  void _showAddGoalSheet(BuildContext context, WidgetRef ref, {Goal? initialGoal}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddGoalSheet(ref, initialGoal: initialGoal),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flag_outlined, size: 80, color: AppColors.textMuted.withValues(alpha: 0.5)),
          const SizedBox(height: AppDimensions.s3),
          const Text(
            'No Goals Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.s1),
          const Text(
            'Set your first financial target!',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(Goal goal, BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.pLarge),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.r3),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                goal.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_note, size: 20, color: AppColors.accent),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _showAddGoalSheet(context, ref, initialGoal: goal),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      goal.estimatedTimeToReach == "Completed!" 
                        ? "Goal Reached!" 
                        : '${goal.estimatedTimeToReach} Remaining',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.s3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                NumberFormat.simpleCurrency(locale: 'en_IN', decimalDigits: 0).format(goal.currentAmount),
                style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'saved',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted,
                  height: 1.8,
                ),
              ),
              const Spacer(),
              Text(
                'Rate: ₹${goal.savingRate.toStringAsFixed(0)} / ${goal.ratePeriod.name}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.s3),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.r1),
            child: LinearProgressIndicator(
              value: goal.progressPercentage,
              backgroundColor: AppColors.background,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: AppDimensions.s2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(goal.progressPercentage * 100).toStringAsFixed(1)}% reached',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                "Target: ${NumberFormat.simpleCurrency(locale: 'en_IN', decimalDigits: 0).format(goal.targetAmount)}",
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddGoalSheet extends StatefulWidget {
  final WidgetRef ref;
  final Goal? initialGoal;
  const _AddGoalSheet(this.ref, {this.initialGoal});

  @override
  State<_AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends State<_AddGoalSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _rateController;
  late SavingRatePeriod _selectedPeriod;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialGoal?.title ?? '');
    _amountController = TextEditingController(text: widget.initialGoal?.targetAmount.toStringAsFixed(0) ?? '');
    _rateController = TextEditingController(text: widget.initialGoal?.savingRate.toStringAsFixed(0) ?? '');
    _selectedPeriod = widget.initialGoal?.ratePeriod ?? SavingRatePeriod.monthly;
  }

  String _calculateResult() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final rate = double.tryParse(_rateController.text) ?? 0.0;
    
    if (amount <= 0 || rate <= 0) return "Fill details to calculate";
    
    final units = (amount / rate).ceil();
    String periodStr = "";
    switch (_selectedPeriod) {
      case SavingRatePeriod.daily: periodStr = units == 1 ? "day" : "days"; break;
      case SavingRatePeriod.weekly: periodStr = units == 1 ? "week" : "weeks"; break;
      case SavingRatePeriod.monthly: periodStr = units == 1 ? "month" : "months"; break;
    }
    return "It will take approximately $units $periodStr to reach your goal!";
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialGoal != null;

    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.r4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEditing ? 'Edit Savings Goal' : 'New Savings Goal',
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.s4),
          _buildTextField(_titleController, 'Goal Title (e.g. MacBook Pro, Trip to Bali)', Icons.flag_rounded),
          const SizedBox(height: AppDimensions.s2),
          _buildTextField(_amountController, 'Target Amount (₹)', Icons.currency_rupee, isNumber: true),
          const SizedBox(height: AppDimensions.s2),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildTextField(_rateController, 'Saving Rate', Icons.speed_rounded, isNumber: true),
              ),
              const SizedBox(width: AppDimensions.s2),
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(AppDimensions.r2),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<SavingRatePeriod>(
                      value: _selectedPeriod,
                      dropdownColor: AppColors.surface,
                      items: SavingRatePeriod.values.map((p) {
                        return DropdownMenuItem(
                          value: p,
                          child: Text(p.name, style: const TextStyle(color: AppColors.textPrimary)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedPeriod = val);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.s4),
          Container(
            padding: const EdgeInsets.all(AppDimensions.pNormal),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.r2),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                const SizedBox(width: AppDimensions.s2),
                Expanded(
                  child: Text(
                    _calculateResult(),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.s4),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isEditing ? AppColors.accent : AppColors.primary,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.r2)),
            ),
            onPressed: () {
              final title = _titleController.text;
              final amount = double.tryParse(_amountController.text) ?? 0.0;
              final rate = double.tryParse(_rateController.text) ?? 0.0;

              if (title.isNotEmpty && amount > 0 && rate > 0) {
                 if (isEditing) {
                   final updatedGoal = widget.initialGoal!.copyWith(
                     title: title,
                     targetAmount: amount,
                     savingRate: rate,
                     ratePeriod: _selectedPeriod,
                   );
                   widget.ref.read(goalsProvider.notifier).updateGoal(updatedGoal);
                 } else {
                   final newGoal = Goal(
                     title: title,
                     targetAmount: amount,
                     currentAmount: 0,
                     savingRate: rate,
                     ratePeriod: _selectedPeriod,
                     createdAt: DateTime.now(),
                   );
                   widget.ref.read(goalsProvider.notifier).addGoal(newGoal);
                 }
                 Navigator.pop(context);
              }
            },
            child: Text(isEditing ? 'UPDATE GOAL' : 'CREATE GOAL', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: AppColors.textPrimary),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      onChanged: (_) => setState(() {}),
      inputFormatters: [
        isNumber 
          ? FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
          : FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
      ],
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textMuted),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.r2),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.r2),
          borderSide: const BorderSide(color: AppColors.primary, width: 1),
        ),
      ),
    );
  }
}
