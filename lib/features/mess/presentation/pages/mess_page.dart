import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/mess_sessions_provider.dart';
import '../../domain/models/mess_session.dart';
import '../../../dashboard/presentation/providers/expenses_provider.dart';

final selectedSessionProvider = StateProvider<String>((ref) => 'Breakfast');

class MessPage extends ConsumerWidget {
  const MessPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messState = ref.watch(messSessionsProvider);
    final selectedSession = ref.watch(selectedSessionProvider);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.pNormal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: AppDimensions.s4),
              _buildAttendanceSection(messState, selectedSession, ref),
              const SizedBox(height: AppDimensions.s3),
              _buildCurrentSessionCard(messState, selectedSession, ref, context),
              const SizedBox(height: AppDimensions.s3),
              _buildMonthlyOverviewCard(ref, context),
              const SizedBox(height: AppDimensions.s3),
              _buildComparisonCard(ref),
              const SizedBox(height: AppDimensions.s4), // Extra padding at bottom
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 40,
              width: 40,
            ),
            const SizedBox(width: AppDimensions.s2),
            const Text(
              'Mess Buddy',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAttendanceSection(AsyncValue<List<MessSession>> messState, String selectedSession, WidgetRef ref) {
    return messState.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
      data: (sessions) {
        final matches = sessions.where((s) => s.sessionType == selectedSession);
        final currentSession = matches.isNotEmpty ? matches.first : null;
        
        final isAttending = currentSession != null && currentSession.status == 'Attended';
        final isSkipped = currentSession == null || currentSession.status == 'Skipped';
        final basePrice = ref.watch(sessionPricesProvider)[selectedSession] ?? 0.0; // safe fallback when prices not yet configured

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Daily Attendance',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'LIVE STATUS',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMuted.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.s3),
            // Session Toggle Buttons
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.r3),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: ['Breakfast', 'Lunch', 'Dinner'].map((type) {
                  final isSelected = selectedSession == type;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => ref.read(selectedSessionProvider.notifier).state = type,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppDimensions.r3 - 4),
                        ),
                        child: Center(
                          child: Text(
                            type,
                            style: TextStyle(
                              color: isSelected ? AppColors.primary : AppColors.textMuted,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppDimensions.s2),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.r3),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        ref.read(messSessionsProvider.notifier).toggleSessionAttendance(selectedSession, true, basePrice);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: AppDimensions.s2),
                        decoration: BoxDecoration(
                          color: isAttending ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppDimensions.r3 - 4),
                          border: Border.all(color: isAttending ? AppColors.primary.withValues(alpha: 0.3) : Colors.transparent),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: isAttending ? AppColors.primary : AppColors.textMuted, size: 20),
                            const SizedBox(width: AppDimensions.s1),
                            Text(
                              'Present',
                              style: TextStyle(
                                color: isAttending ? AppColors.primary : AppColors.textPrimary,
                                fontWeight: isAttending ? FontWeight.bold : FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        ref.read(messSessionsProvider.notifier).toggleSessionAttendance(selectedSession, false, basePrice);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: AppDimensions.s2),
                        decoration: BoxDecoration(
                          color: isSkipped ? Colors.redAccent.withValues(alpha: 0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppDimensions.r3 - 4),
                          border: Border.all(color: isSkipped ? Colors.redAccent.withValues(alpha: 0.3) : Colors.transparent),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cancel, color: isSkipped ? Colors.redAccent : AppColors.textMuted, size: 20),
                            const SizedBox(width: AppDimensions.s1),
                            Text(
                              'Absent',
                              style: TextStyle(
                                color: isSkipped ? Colors.redAccent : AppColors.textPrimary,
                                fontWeight: isSkipped ? FontWeight.bold : FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCurrentSessionCard(AsyncValue<List<MessSession>> messState, String selectedSession, WidgetRef ref, BuildContext context) {
    final sessions = messState.value ?? [];
    final matches = sessions.where((s) => s.sessionType == selectedSession);
    final currentSession = matches.isNotEmpty ? matches.first : null;
    
    final basePrices = ref.watch(sessionPricesProvider);
    final displayedCost = currentSession != null && currentSession.status == 'Attended' ? currentSession.sessionCost : (basePrices[selectedSession] ?? 0.0);
    
    final addons = ref.watch(addonsProvider);

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Session',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedSession,
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Text(
                        '₹${displayedCost.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings, size: 18, color: AppColors.primary),
                        onPressed: () => _showCustomizationDialog(context, ref),
                        tooltip: 'Customize Prices',
                      ),
                    ],
                  ),
                  const Text(
                    'Standard Rate',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.s3),
          const Text(
            'ADD-ONS (EXTRAS)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: AppDimensions.s3),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: [
                ...addons.map((addon) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: SizedBox(
                      width: 90,
                      child: _buildAddonItem(
                        addon: addon,
                        sessionType: selectedSession,
                        ref: ref,
                      ),
                    ),
                  );
                }),
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: SizedBox(
                    width: 90,
                    child: _buildOtherAddonItem(
                      sessionType: selectedSession,
                      ref: ref,
                      context: context,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (currentSession != null && currentSession.addons.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppDimensions.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ADDED ITEMS',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: currentSession.addons.map((addonStr) {
                      double itemPrice = 0.0;
                      String displayTitle = addonStr;
                      
                      if (addonStr.contains('|')) {
                        final parts = addonStr.split('|');
                        displayTitle = parts[0];
                        itemPrice = double.tryParse(parts[1]) ?? 0.0;
                      } else {
                        final found = addons.where((a) => a.name == addonStr);
                        if (found.isNotEmpty) itemPrice = found.first.price;
                      }

                      return Chip(
                        label: Text(
                          '$displayTitle (₹${itemPrice.toStringAsFixed(0)})',
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                        ),
                        backgroundColor: AppColors.background,
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white54),
                        onDeleted: () {
                          ref.read(messSessionsProvider.notifier).removeAddonFromSession(selectedSession, addonStr, itemPrice);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddonItem({
    required AddonItem addon,
    required String sessionType,
    required WidgetRef ref,
  }) {
    IconData getIconData(String name) {
      if (name.toLowerCase() == 'egg') return Icons.egg_outlined;
      if (name.toLowerCase() == 'chicken') return Icons.restaurant;
      if (name.toLowerCase() == 'milk') return Icons.water_drop_outlined;
      return Icons.fastfood;
    }
    Color getIconColor(String name) {
      if (name.toLowerCase() == 'egg') return Colors.orangeAccent;
      if (name.toLowerCase() == 'chicken') return Colors.deepOrangeAccent;
      if (name.toLowerCase() == 'milk') return Colors.lightBlueAccent;
      return Colors.grey;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.pNormal),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppDimensions.r2),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(getIconData(addon.name), color: getIconColor(addon.name), size: 28),
              const SizedBox(height: AppDimensions.s1),
              Text(
                addon.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '(₹${addon.price.toStringAsFixed(0)})',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: -8,
          right: -8,
          child: GestureDetector(
            onTap: () {
              final basePrice = ref.read(sessionPricesProvider)[sessionType] ?? 0.0;
              ref.read(messSessionsProvider.notifier).addAddonToSession(sessionType, addon.name, addon.price, basePrice: basePrice);
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_circle, color: AppColors.primary, size: 22),
            ),
          ),
        ),
        Positioned(
          bottom: -8,
          right: -8,
          child: GestureDetector(
            onTap: () {
              ref.read(messSessionsProvider.notifier).removeAddonFromSession(sessionType, addon.name, addon.price);
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.remove_circle, color: Colors.redAccent, size: 22),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtherAddonItem({
    required String sessionType,
    required WidgetRef ref,
    required BuildContext context,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.pNormal),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppDimensions.r2),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.more_horiz, color: Colors.blueAccent, size: 28),
              SizedBox(height: AppDimensions.s1),
              Text(
                'Other',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 2),
              Text(
                '(Custom)',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: -8,
          right: -8,
          child: GestureDetector(
            onTap: () => _showOtherAddonDialog(context, ref, sessionType),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_circle, color: AppColors.primary, size: 22),
            ),
          ),
        ),
      ],
    );
  }

  void _showOtherAddonDialog(BuildContext context, WidgetRef ref, String sessionType) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Add Custom Item', style: TextStyle(color: AppColors.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: AppColors.textPrimary),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))],
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                  labelStyle: TextStyle(color: AppColors.textMuted),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.textPrimary),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                decoration: const InputDecoration(
                  labelText: 'Price',
                  labelStyle: TextStyle(color: AppColors.textMuted),
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () {
                final name = nameController.text.trim();
                final price = double.tryParse(priceController.text) ?? 0.0;
                if (name.isNotEmpty) {
                   ref.read(messSessionsProvider.notifier).addAddonToSession(sessionType, "$name|$price", price);
                }
                Navigator.pop(ctx);
              },
              child: const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showCustomizationDialog(BuildContext context, WidgetRef ref) {
    final sessionPrices = ref.read(sessionPricesProvider);
    final addons = ref.read(addonsProvider);

    final breakfastController = TextEditingController(text: sessionPrices['Breakfast']?.toStringAsFixed(0));
    final lunchController = TextEditingController(text: sessionPrices['Lunch']?.toStringAsFixed(0));
    final dinnerController = TextEditingController(text: sessionPrices['Dinner']?.toStringAsFixed(0));

    final addonControllers = addons.map((a) => TextEditingController(text: a.price.toStringAsFixed(0))).toList();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Customize Prices', style: TextStyle(color: AppColors.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Session Prices', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                const SizedBox(height: 8),
                _buildPriceField('Breakfast', breakfastController),
                _buildPriceField('Lunch', lunchController),
                _buildPriceField('Dinner', dinnerController),
                const SizedBox(height: 16),
                const Text('Add-ons', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                const SizedBox(height: 8),
                for (int i = 0; i < addons.length; i++)
                  _buildPriceField(addons[i].name, addonControllers[i]),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () {
                // Update session prices
                ref.read(sessionPricesProvider.notifier).setPrices({
                  'Breakfast': double.tryParse(breakfastController.text) ?? 0.0,
                  'Lunch': double.tryParse(lunchController.text) ?? 0.0,
                  'Dinner': double.tryParse(dinnerController.text) ?? 0.0,
                });

                // Update add-ons
                final newAddons = <AddonItem>[];
                for (int i = 0; i < addons.length; i++) {
                  newAddons.add(addons[i].copyWith(
                    price: double.tryParse(addonControllers[i].text) ?? 0.0,
                  ));
                }
                ref.read(addonsProvider.notifier).setAddons(newAddons);

                Navigator.pop(ctx);
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPriceField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textPrimary)),
          SizedBox(
            width: 80,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                prefixText: '₹ ',
                prefixStyle: TextStyle(color: AppColors.textMuted),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyOverviewCard(WidgetRef ref, BuildContext context) {
    final overviewState = ref.watch(monthlyOverviewProvider);
    
    return overviewState.when(
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator(color: AppColors.primary))),
      error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
      data: (data) {
        final totalExpense = data['totalExpense'] as double;
        final messCount = data['messCount'] as int;
        final avgCost = data['avgCost'] as double;

        return Container(
          padding: const EdgeInsets.all(AppDimensions.pLarge),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.surface,
                Color(0xFF1E1F29), // slightly different surface tint
              ],
            ),
            borderRadius: BorderRadius.circular(AppDimensions.r3),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'MONTHLY OVERVIEW',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: AppColors.textMuted,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_month, color: AppColors.primary, size: 20),
                    onPressed: () async {
                      final selected = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(DateTime.now().year, DateTime.now().month, 1),
                        lastDate: DateTime(DateTime.now().year, DateTime.now().month + 1, 0),
                        helpText: 'Select Track Start Date (Resets Next Month)',
                      );
                      if (selected != null) {
                        ref.read(trackingStartDateProvider.notifier).state = selected;
                      }
                    },
                    tooltip: 'Set Tracking Start Date',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.s2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₹${totalExpense.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Text(
                        'Total Mess Expenditure',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: AppColors.primary, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Active',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2),
                      Text(
                        'CURRENT CYCLE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: AppDimensions.s3),
              Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
              const SizedBox(height: AppDimensions.s3),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.calendar_today, color: Colors.lightBlueAccent, size: 20),
                        ),
                        const SizedBox(width: AppDimensions.s1),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$messCount Days',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Text(
                              'Mess Count',
                              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.money, color: Colors.orangeAccent, size: 20),
                        ),
                        const SizedBox(width: AppDimensions.s1),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '₹${avgCost.toStringAsFixed(0)}/day',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Text(
                              'Average Cost',
                              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildComparisonCard(WidgetRef ref) {
    final outsideFoodSpent = ref.watch(outsideFoodSpendingProvider);
    final messFoodSpent = ref.watch(messFoodSpendingProvider);

    // Calculate relative progress. The larger value will be the 100% baseline (1.0).
    final maxValue = (outsideFoodSpent > messFoodSpent ? outsideFoodSpent : messFoodSpent);
    final outsideProgress = maxValue > 0 ? (outsideFoodSpent / maxValue) : 0.0;
    final messProgress = maxValue > 0 ? (messFoodSpent / maxValue) : 0.0;

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
              const Text(
                'Mess vs Outside',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: messFoodSpent <= outsideFoodSpent
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : Colors.redAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  messFoodSpent <= outsideFoodSpent
                      ? 'SAVING ₹${(outsideFoodSpent - messFoodSpent).toStringAsFixed(0)}'
                      : 'OVER BUDGET ₹${(messFoodSpent - outsideFoodSpent).toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: messFoodSpent <= outsideFoodSpent
                        ? AppColors.primary
                        : Colors.redAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.s4),
          _buildProgressBarRow(
            label: 'Eating Outside',
            amount: '₹${outsideFoodSpent.toStringAsFixed(0)}',
            progress: outsideProgress, 
            color: Colors.lightBlueAccent,
          ),
          const SizedBox(height: AppDimensions.s3),
          _buildProgressBarRow(
            label: 'Current Mess Cost',
            amount: '₹${messFoodSpent.toStringAsFixed(0)}',
            progress: messProgress,
            color: messFoodSpent <= outsideFoodSpent
                ? AppColors.primary
                : Colors.redAccent,
          ),
          const SizedBox(height: AppDimensions.s4),
          Text(
            messFoodSpent <= outsideFoodSpent
                ? 'Your mess spending is more efficient than eating outside.'
                : 'Your mess expenditure currently exceeds outside eating spending.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBarRow({
    required String label,
    required String amount,
    required double progress,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              amount,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.r1),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.background,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 12,
          ),
        ),
      ],
    );
  }
}

