import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../../dashboard/domain/models/expense.dart';
import '../../../dashboard/presentation/providers/expenses_provider.dart';

class AddExpensePage extends ConsumerStatefulWidget {
  const AddExpensePage({super.key});

  @override
  ConsumerState<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends ConsumerState<AddExpensePage> {
  String _amount = '';
  String _category = 'Food';
  final TextEditingController _noteController = TextEditingController();
  bool _isSplitEnabled = true;

  void _submitExpense() {
    if (_amount.isEmpty) return;
    
    final parsedAmount = double.tryParse(_amount) ?? 0.0;
    if (parsedAmount <= 0) return;

    final newExpense = Expense(
      title: _noteController.text.isNotEmpty ? _noteController.text : 'Quick Add: $_category',
      amount: parsedAmount,
      payerId: 1, // Currently logged in user mock ID
      category: _category,
      date: DateTime.now(),
    );

    ref.read(expensesProvider.notifier).addExpense(newExpense);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expense added successfully!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // If we popped as a modal: context.pop();
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppDimensions.s4),
                    _buildAmountInput(),
                    const SizedBox(height: AppDimensions.s4),
                    const Text(
                      'Category',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.s3),
                    _buildCategoriesRow(),
                    const SizedBox(height: AppDimensions.s4),
                    const Text(
                      'Quick Add',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.s3),
                    _buildQuickAddGrid(),
                    const SizedBox(height: AppDimensions.s4),
                    const Text(
                      'Note',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.s2),
                    _buildNoteInput(),
                    const SizedBox(height: AppDimensions.s4),
                    const Text(
                      'Date',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.s2),
                    _buildDateSelector(),
                    const SizedBox(height: AppDimensions.s3),
                    _buildToggleTile(
                      icon: Icons.repeat,
                      title: 'Recurring',
                      value: false,
                      onChanged: (val) {},
                    ),
                    const SizedBox(height: AppDimensions.s3),
                    _buildToggleTile(
                      icon: Icons.people_alt_outlined,
                      title: 'Split with Roommates',
                      value: _isSplitEnabled,
                      onChanged: (val) {
                        setState(() { _isSplitEnabled = val; });
                      },
                      activeColor: Colors.cyanAccent,
                    ),
                    if (_isSplitEnabled) ...[
                      const SizedBox(height: AppDimensions.s2),
                      _buildSplitCard(),
                    ],
                    const SizedBox(height: 120), // Padding for bottom button
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildPrimaryButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.pLarge),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.close, color: AppColors.textPrimary),
          ),
          const Text(
            'Add Expense',
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.history, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInput() {
    return Column(
      children: [
        const Text(
          'Transaction Amount',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: AppDimensions.s1),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            const Text(
              '₹',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppDimensions.s1),
            IntrinsicWidth(
              child: TextField(
                autofocus: true,
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  color: _amount.isNotEmpty ? AppColors.textPrimary : AppColors.textMuted.withValues(alpha: 0.3),
                ),
                decoration: InputDecoration(
                  hintText: '0.00',
                  hintStyle: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.3)),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (val) {
                  setState(() {
                    _amount = val;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.s3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppDimensions.rMax),
            border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.5)),
          ),
          child: Text(
            'PERSONAL LEDGER',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted.withValues(alpha: 0.8),
              letterSpacing: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildCategoryItem('Food', Icons.restaurant, _category == 'Food'),
        _buildCategoryItem('Rent', Icons.home, _category == 'Rent'),
        _buildCategoryItem('Mess', Icons.fastfood, _category == 'Mess'),
        _buildCategoryItem('Transport', Icons.directions_bus, _category == 'Transport'),
      ],
    );
  }

  Widget _buildCategoryItem(String name, IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _category = name;
        });
      },
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.r2),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.05),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.textMuted, size: 24),
            const SizedBox(height: 4),
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAddGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: AppDimensions.s2,
      mainAxisSpacing: AppDimensions.s2,
      childAspectRatio: 2.2,
      children: [
        _buildQuickAddItem('Coffee', 'Last: ₹45.00', Icons.local_cafe, Colors.orangeAccent),
        _buildQuickAddItem('Snacks', 'Last: ₹120.00', Icons.icecream, Colors.cyanAccent),
        _buildQuickAddItem('Prints', 'Last: ₹15.00', Icons.print, AppColors.primary),
        _buildQuickAddItem('Other', 'Recent items', Icons.more_horiz, AppColors.textMuted),
      ],
    );
  }

  Widget _buildQuickAddItem(String title, String subtitle, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.r2),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: AppDimensions.s1),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pNormal),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.r2),
      ),
      child: TextField(
        controller: _noteController,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          icon: Icon(Icons.edit_note, color: AppColors.textMuted.withValues(alpha: 0.5)),
          hintText: 'What was this for?',
          hintStyle: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.5)),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.pLarge),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.r2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, color: AppColors.textMuted.withValues(alpha: 0.5), size: 20),
              const SizedBox(width: AppDimensions.s2),
              const Text(
                'Today, Oct 24',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const Icon(Icons.chevron_right, color: AppColors.textMuted),
        ],
      ),
    );
  }

  Widget _buildToggleTile({required IconData icon, required String title, required bool value, required Function(bool) onChanged, Color? activeColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pNormal, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.r2),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: activeColor ?? AppColors.textMuted.withValues(alpha: 0.5), size: 20),
              const SizedBox(width: AppDimensions.s2),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: activeColor ?? AppColors.primary,
            activeTrackColor: (activeColor ?? AppColors.primary).withValues(alpha: 0.3),
            inactiveThumbColor: AppColors.textMuted,
            inactiveTrackColor: AppColors.background,
          ),
        ],
      ),
    );
  }

  Widget _buildSplitCard() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.pLarge),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.r2),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Splitting with Room 302',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppDimensions.s1),
              Row(
                children: [
                  _buildMiniAvatar('A', Colors.orangeAccent),
                  _buildMiniAvatar('B', Colors.cyanAccent),
                  _buildMiniAvatar('S', AppColors.accent),
                  _buildMiniAvatar('+1', AppColors.background),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Split Equally',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyanAccent,
                ),
              ),
              const SizedBox(height: AppDimensions.s1),
              Text(
                'Each pays',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted.withValues(alpha: 0.7),
                ),
              ),
              Text(
                _amount.isNotEmpty ? '₹${(double.parse(_amount) / 4).toStringAsFixed(2)}' : '₹0.00',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyanAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniAvatar(String text, Color color) {
    return Align(
      widthFactor: 0.7,
      child: CircleAvatar(
        radius: 14,
        backgroundColor: color,
        child: Text(text, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildPrimaryButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pLarge),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.primary, // 0xFF818CF8
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: _submitExpense,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Add Expense',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
