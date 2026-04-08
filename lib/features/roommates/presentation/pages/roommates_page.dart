import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../providers/roommate_balances_provider.dart';
import '../providers/roommates_provider.dart';
import '../../domain/models/roommate.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class RoommatesPage extends ConsumerStatefulWidget {
  const RoommatesPage({super.key});

  @override
  ConsumerState<RoommatesPage> createState() => _RoommatesPageState();
}

class _RoommatesPageState extends ConsumerState<RoommatesPage> {
  final Set<int> _selectedRoommates = {};
  final TextEditingController _quickSplitAmountController = TextEditingController(text: '0');
  int? _quickSplitPayerId; // null = Me
  bool _isCustomSplitSelection = false;
  final Set<int?> _selectedSplitIds = {}; // null = Me
  bool _hasAutoSeeded = false;

  @override
  void initState() {
    super.initState();
    // Seed roommates from profile once data is ready
    WidgetsBinding.instance.addPostFrameCallback((_) => _seedRoommatesFromProfile());
  }

  Future<void> _seedRoommatesFromProfile() async {
    if (_hasAutoSeeded) return;
    final roommatesState = ref.read(roommatesProvider);
    // Only auto-seed if no roommates exist yet
    final existingRoommates = roommatesState.value ?? [];
    if (existingRoommates.isNotEmpty) {
      _hasAutoSeeded = true;
      return;
    }
    final authData = ref.read(authProvider).value;
    final profile = authData?.profile;
    final roommateNames = profile?.roommateName;
    if (roommateNames != null && roommateNames.isNotEmpty) {
      final names = roommateNames.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      for (final name in names) {
        await ref.read(roommatesProvider.notifier).addRoommate(name, '');
      }
    }
    _hasAutoSeeded = true;
  }

  @override
  void dispose() {
    _quickSplitAmountController.dispose();
    super.dispose();
  }

  // ─── Add Roommate Dialog ─────────────────────────────────────────────
  void _showAddRoommateDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final amountController = TextEditingController(text: '0');
    bool isTheyOweMe = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Add Roommate', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))],
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    labelStyle: const TextStyle(color: AppColors.textMuted),
                    hintText: 'Enter name',
                    prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withAlpha(25))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Phone Number (Optional)',
                    labelStyle: const TextStyle(color: AppColors.textMuted),
                    hintText: '10-digit number',
                    prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.primary),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withAlpha(25))),
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(color: Colors.white12),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('INITIAL BALANCE', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                  decoration: InputDecoration(
                    prefixText: '₹ ',
                    prefixStyle: const TextStyle(color: AppColors.textMuted),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withAlpha(25))),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setDialogState(() => isTheyOweMe = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isTheyOweMe ? Colors.cyanAccent.withAlpha(30) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isTheyOweMe ? Colors.cyanAccent.withAlpha(60) : Colors.transparent),
                            ),
                            child: Center(
                              child: Text('They Owe Me', style: TextStyle(color: isTheyOweMe ? Colors.cyanAccent : AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setDialogState(() => isTheyOweMe = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: !isTheyOweMe ? Colors.orangeAccent.withAlpha(30) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: !isTheyOweMe ? Colors.orangeAccent.withAlpha(60) : Colors.transparent),
                            ),
                            child: Center(
                              child: Text('I Owe Them', style: TextStyle(color: !isTheyOweMe ? Colors.orangeAccent : AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  final roommates = ref.read(roommatesProvider).value ?? [];
                  final isDuplicate = roommates.any((r) => r.name.toLowerCase() == name.toLowerCase());

                  if (isDuplicate) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('⚠️ Roommate "$name" already exists!'), backgroundColor: Colors.orangeAccent, behavior: SnackBarBehavior.floating),
                    );
                    return;
                  }

                  final newRoommate = await ref.read(roommatesProvider.notifier).addRoommate(name, phoneController.text.trim());
                  final amount = double.tryParse(amountController.text.trim()) ?? 0;
                  if (amount > 0 && newRoommate.id != null) {
                    final rid = newRoommate.id.toString();
                    if (isTheyOweMe) {
                      ref.read(roommateBalancesProvider.notifier).addSplit(rid, amount);
                    } else {
                      ref.read(roommateBalancesProvider.notifier).addOwe(rid, amount);
                    }
                  }
                  

                  if (context.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Add Roommate', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteSelectedRoommates(WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Roommates?', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to remove ${_selectedRoommates.length} roommates?', style: const TextStyle(color: AppColors.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted))),
          TextButton(
            onPressed: () {
              for (var id in _selectedRoommates) {
                ref.read(roommatesProvider.notifier).deleteRoommate(id);
              }
              setState(() => _selectedRoommates.clear());
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  // ─── Amount & Settlement Dialogs ──────────────────────────────────────
  void _showAmountPopup({required String roommateId, required String roommateName, required String type, required double currentAmount}) {
    if (currentAmount <= 0) return;

    _showSettleAmountDialog(
      title: type == 'split' ? 'Settle Receivable' : 'Settle Payable',
      subtitle: type == 'split' ? 'How much did $roommateName pay you?' : 'How much did you pay $roommateName?',
      color: type == 'split' ? Colors.cyanAccent : Colors.orangeAccent,
      maxAmount: currentAmount,
      onSettle: (amount) {
        if (type == 'split') {
          ref.read(roommateBalancesProvider.notifier).settleSplit(roommateId, amount);
        } else {
          ref.read(roommateBalancesProvider.notifier).settleOwe(roommateId, amount);
        }
      },
    );
  }

  void _showSettleAmountDialog({required String title, required String subtitle, required Color color, required double maxAmount, required Function(double) onSettle}) {
    final controller = TextEditingController(text: maxAmount.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
              style: TextStyle(color: color, fontSize: 32, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: '₹ ',
                prefixStyle: const TextStyle(color: AppColors.textMuted, fontSize: 24),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: color.withAlpha(50))),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: color)),
              ),
            ),
            const SizedBox(height: 8),
            Text('Max: ₹${maxAmount.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              final amt = double.tryParse(controller.text.trim()) ?? 0;
              if (amt > 0) {
                onSettle(amt > maxAmount ? maxAmount : amt);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Confirm Settle', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(String roommateId, String name, RoommateBalanceEntry entry) {
    final splitCtrl = TextEditingController(text: entry.split.toStringAsFixed(0));
    final oweCtrl = TextEditingController(text: entry.owe.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Edit Balances: $name', style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: splitCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
              style: const TextStyle(color: Colors.cyanAccent),
              decoration: const InputDecoration(labelText: 'They Owe You (Split)', labelStyle: TextStyle(color: AppColors.textMuted), prefixText: '₹ '),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: oweCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
              style: const TextStyle(color: Colors.orangeAccent),
              decoration: const InputDecoration(labelText: 'You Owe Them (Owe)', labelStyle: TextStyle(color: AppColors.textMuted), prefixText: '₹ '),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final newSplit = double.tryParse(splitCtrl.text.trim()) ?? entry.split;
              final newOwe = double.tryParse(oweCtrl.text.trim()) ?? entry.owe;
              ref.read(roommateBalancesProvider.notifier).editSplit(roommateId, newSplit);
              ref.read(roommateBalancesProvider.notifier).editOwe(roommateId, newOwe);
              Navigator.pop(ctx);
            },
            child: const Text('Save', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _settleSelectedRoommates() {
    final ids = _selectedRoommates.map((e) => e.toString()).toSet();
    final balances = ref.read(roommateBalancesProvider);

    double totalSplit = 0;
    double totalOwe = 0;
    for (var id in ids) {
      final b = balances[id] ?? const RoommateBalanceEntry();
      totalSplit += b.split;
      totalOwe += b.owe;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            const Text('Settle Selection', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            Text('${ids.length} roommates selected', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSettleOption(
              icon: Icons.call_received,
              color: Colors.cyanAccent,
              title: 'Settle Split Amount',
              subtitle: 'They paid you ₹${totalSplit.toStringAsFixed(0)}',
              onTap: () {
                Navigator.pop(ctx);
                _showSettleAmountDialog(
                  title: 'Settle Split',
                  subtitle: 'Enter amount they paid you (will be divided)',
                  color: Colors.cyanAccent,
                  maxAmount: totalSplit,
                  onSettle: (amt) {
                    ref.read(roommateBalancesProvider.notifier).settleMultipleSplit(ids, amt);
                    setState(() => _selectedRoommates.clear());
                  },
                );
              },
            ),
            const SizedBox(height: 12),
            _buildSettleOption(
              icon: Icons.call_made,
              color: Colors.orangeAccent,
              title: 'Settle Owes Amount',
              subtitle: 'You paid them ₹${totalOwe.toStringAsFixed(0)}',
              onTap: () {
                Navigator.pop(ctx);
                _showSettleAmountDialog(
                  title: 'Settle Owes',
                  subtitle: 'Enter amount you paid them (will be divided)',
                  color: Colors.orangeAccent,
                  maxAmount: totalOwe,
                  onSettle: (amt) {
                    ref.read(roommateBalancesProvider.notifier).settleMultipleOwe(ids, amt);
                    setState(() => _selectedRoommates.clear());
                  },
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }

  void _handleQuickSplit() {
    final amount = double.tryParse(_quickSplitAmountController.text.trim()) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid amount')));
      return;
    }

    final roommates = ref.read(roommatesProvider).value ?? [];
    if (roommates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add roommates first!')));
      return;
    }

    // Determine split members
    final List<int?> splittingMembers;
    if (_isCustomSplitSelection) {
      splittingMembers = _selectedSplitIds.isEmpty ? [null, ...roommates.map((r) => r.id)] : _selectedSplitIds.toList();
    } else {
      splittingMembers = [null, ...roommates.map((r) => r.id)];
    }

    if (splittingMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('At least one person must be in the split!')));
      return;
    }

    final totalPeople = splittingMembers.length;
    final share = amount / totalPeople;

    if (_quickSplitPayerId == null) {
      // Me paid -> each roommate in the split owes me their share
      for (final rId in splittingMembers) {
        if (rId != null) {
          ref.read(roommateBalancesProvider.notifier).addSplit(rId.toString(), share);
        }
      }
    } else {
      // Roommate X paid. If "Me" is in the split, I owe share to X.
      if (splittingMembers.contains(null)) {
        ref.read(roommateBalancesProvider.notifier).addOwe(_quickSplitPayerId!.toString(), share);
      }
    }

    _quickSplitAmountController.text = '0';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Split ₹${amount.toStringAsFixed(0)} with the circle! (Each share: ₹${share.toStringAsFixed(0)})'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildSettleOption({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withAlpha(50),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color.withAlpha(120)),
          ],
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final roommatesState = ref.watch(roommatesProvider);
    final balances = ref.watch(roommateBalancesProvider);
    final totalOthersOwe = ref.watch(totalOthersOweYouProvider);
    final totalYouOwe = ref.watch(totalYouOweProvider);
    final balancesNotifier = ref.read(roommateBalancesProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.pNormal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(balancesNotifier),
              const SizedBox(height: AppDimensions.s4),
              _buildTitleRow(context, ref),
              const SizedBox(height: AppDimensions.s4),

              // ── Total You Owe ──
              _buildOweCard(
                title: 'Total You Owe',
                amount: '₹${totalYouOwe.toStringAsFixed(0)}',
                status: totalYouOwe > 0 ? 'PENDING' : 'CLEAR',
                statusColor: Colors.orangeAccent,
                borderColor: Colors.orangeAccent,
                showAvatars: true,
                showSettleButton: false,
                roommatesState: roommatesState,
              ),
              const SizedBox(height: AppDimensions.s2),

              // ── Others Owe You ──
              _buildOweCard(
                title: 'Others Owe You',
                amount: '₹${totalOthersOwe.toStringAsFixed(0)}',
                status: totalOthersOwe > 0 ? 'RECEIVABLE' : 'CLEAR',
                statusColor: Colors.cyanAccent,
                borderColor: Colors.cyanAccent,
                showAvatars: false,
                showSettleButton: totalOthersOwe > 0,
                roommatesState: roommatesState,
              ),
              const SizedBox(height: AppDimensions.s4),

              // ── Active Circle header ──
              const Text(
                'ACTIVE CIRCLE',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.textMuted),
              ),
              const SizedBox(height: AppDimensions.s2),

              // ── Settle selected button ──
              if (_selectedRoommates.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: Text('Settle ${_selectedRoommates.length} Selected'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent,
                        foregroundColor: AppColors.background,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _settleSelectedRoommates,
                    ),
                  ),
                ),

              // ── Roommate list ──
              roommatesState.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
                error: (error, _) => Center(child: Text('Error: $error', style: const TextStyle(color: Colors.red))),
                data: (roommates) {
                  if (roommates.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(AppDimensions.pNormal),
                      child: Text('No roommates added yet.', style: TextStyle(color: AppColors.textMuted)),
                    );
                  }
                  return Column(
                    children: roommates.map((roommate) {
                      final isSelected = roommate.id != null && _selectedRoommates.contains(roommate.id);
                      final rid = (roommate.id ?? 0).toString();
                      final entry = balances[rid] ?? const RoommateBalanceEntry();
                      final total = entry.split + entry.owe;

                      return _buildRoommateItem(
                        id: roommate.id,
                        name: roommate.name,
                        subtitle: roommate.phone.isNotEmpty ? roommate.phone : 'Added recently',
                        avatarInitials: roommate.name.isNotEmpty ? roommate.name[0].toUpperCase() : '?',
                        isSelected: isSelected,
                        entry: entry,
                        total: total,
                        onChanged: (bool? val) {
                          if (roommate.id == null) return;
                          setState(() {
                            if (val == true) {
                              _selectedRoommates.add(roommate.id!);
                            } else {
                              _selectedRoommates.remove(roommate.id!);
                            }
                          });
                        },
                        onSplitTap: () => _showAmountPopup(
                          roommateId: rid,
                          roommateName: roommate.name,
                          type: 'split',
                          currentAmount: entry.split,
                        ),
                        onOweTap: () => _showAmountPopup(
                          roommateId: rid,
                          roommateName: roommate.name,
                          type: 'owe',
                          currentAmount: entry.owe,
                        ),
                        onEditTap: () => _showEditDialog(rid, roommate.name, entry),
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: AppDimensions.s4),
              _buildQuickSplitCard(roommatesState),
              const SizedBox(height: AppDimensions.pHuge * 2),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // WIDGET BUILDERS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildHeader(RoommateBalancesNotifier notifier) {
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
              style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ],
        ),
        // Undo / Redo
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.undo, color: notifier.canUndo ? AppColors.primary : AppColors.textMuted.withAlpha(75)),
              tooltip: 'Undo',
              onPressed: notifier.canUndo
                  ? () {
                      notifier.undo();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('↩ Undone'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 1)),
                      );
                    }
                  : null,
            ),
            IconButton(
              icon: Icon(Icons.redo, color: notifier.canRedo ? AppColors.primary : AppColors.textMuted.withAlpha(75)),
              tooltip: 'Redo',
              onPressed: notifier.canRedo
                  ? () {
                      notifier.redo();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('↪ Redone'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 1)),
                      );
                    }
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTitleRow(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Roommates',
                style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            Text('Manage shared expenses', style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
          ],
        ),
        Row(
          children: [
            if (_selectedRoommates.isNotEmpty) ...[
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () => _deleteSelectedRoommates(ref),
                tooltip: 'Delete Selected',
              ),
              const SizedBox(width: 8),
            ],
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(230),
                borderRadius: BorderRadius.circular(AppDimensions.rMax),
                boxShadow: [BoxShadow(color: AppColors.primary.withAlpha(100), blurRadius: 20, offset: const Offset(0, 4))],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppDimensions.rMax),
                  onTap: () => _showAddRoommateDialog(context, ref),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_add_alt_1, size: 16, color: AppColors.background),
                        SizedBox(width: 8),
                        Text('Add\nRoommate',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.background)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOweCard({
    required String title,
    required String amount,
    required String status,
    required Color statusColor,
    required Color borderColor,
    required bool showAvatars,
    required bool showSettleButton,
    required AsyncValue roommatesState,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.r3),
        border: Border.all(color: Colors.white.withAlpha(12)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 100,
            decoration: BoxDecoration(
              color: borderColor,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(AppDimensions.r3), bottomLeft: Radius.circular(AppDimensions.r3)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.pLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, color: AppColors.textMuted)),
                  const SizedBox(height: AppDimensions.s1),
                  Row(
                    children: [
                      Text(amount,
                          style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(width: AppDimensions.s1),
                      Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, color: statusColor)),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.s2),
                  if (showAvatars)
                    roommatesState.maybeWhen(
                      data: (roommates) {
                        final list = (roommates as List).take(5).toList();
                        if (list.isEmpty) return const SizedBox();
                        return Row(
                          children: list
                              .map((r) => Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: _buildAvatarStack(r.name.isNotEmpty ? r.name[0].toUpperCase() : '?'),
                                  ))
                              .toList(),
                        );
                      },
                      orElse: () => const SizedBox(),
                    ),
                  if (showSettleButton)
                    GestureDetector(
                      onTap: () {
                        final balances = ref.read(roommateBalancesProvider);
                        final ids = balances.entries.where((e) => e.value.split > 0).map((e) => e.key).toSet();
                        if (ids.isNotEmpty) {
                          ref.read(roommateBalancesProvider.notifier).settleMultiple(ids);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('✅ All receivables settled!'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(AppDimensions.rMax)),
                        child: const Text('Settle Now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.background)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarStack(String initials) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: AppColors.surfaceTranslucent,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.background, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(initials, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
    );
  }

  Widget _buildRoommateItem({
    int? id,
    required String name,
    required String subtitle,
    required String avatarInitials,
    required bool isSelected,
    required RoommateBalanceEntry entry,
    required double total,
    required ValueChanged<bool?> onChanged,
    required VoidCallback onSplitTap,
    required VoidCallback onOweTap,
    required VoidCallback onEditTap,
  }) {
    final hasBalance = entry.split > 0 || entry.owe > 0;
    final statusColor = hasBalance ? Colors.orangeAccent : Colors.white.withAlpha(75);

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.s2),
      padding: const EdgeInsets.all(AppDimensions.pNormal),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.surface.withAlpha(200) : AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.r3),
        border: Border.all(color: isSelected ? AppColors.primary : Colors.white.withAlpha(12)),
      ),
      child: Column(
        children: [
          // ── Top row: checkbox + avatar + name + total + edit ──
          Row(
            children: [
              Checkbox(value: isSelected, onChanged: onChanged, activeColor: AppColors.primary),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.background,
                    child: Text(avatarInitials, style: const TextStyle(color: AppColors.textMuted, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surface, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppDimensions.s2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
              // Split & Owe chips
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Total
                  Text(
                    '₹${total.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: total > 0 ? Colors.white : AppColors.textMuted,
                    ),
                  ),
                  Text(
                    total > 0 ? 'PENDING' : 'SETTLED',
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              // Edit button
              IconButton(
                icon: const Icon(Icons.edit, size: 16, color: AppColors.textMuted),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Edit amounts',
                onPressed: onEditTap,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // ── Bottom row: Split & Owe chips ──
          Row(
            children: [
              const SizedBox(width: 52), // align with name column
              GestureDetector(
                onTap: onSplitTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.cyanAccent.withAlpha(75)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('split ', style: TextStyle(fontSize: 11, color: Colors.cyanAccent)),
                      Text(
                        '₹${entry.split.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.cyanAccent),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onOweTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orangeAccent.withAlpha(75)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('owe ', style: TextStyle(fontSize: 11, color: Colors.orangeAccent)),
                      Text(
                        '₹${entry.owe.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orangeAccent),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSplitCard(AsyncValue<List<Roommate>> roommatesState) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.pLarge),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.r3),
        border: Border.all(color: Colors.white.withAlpha(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(AppDimensions.r2)),
                child: const Icon(Icons.receipt_long_rounded, color: Colors.lightBlueAccent, size: 24),
              ),
              const SizedBox(width: AppDimensions.s2),
              const Text('Quick Split',
                  style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: AppDimensions.s4),
          const Text('WHO PAID?',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.textMuted)),
          const SizedBox(height: AppDimensions.s2),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: [
                _buildWhoPaidChip(
                  name: 'Me',
                  isSelected: _quickSplitPayerId == null,
                  initials: 'M',
                  onTap: () => setState(() => _quickSplitPayerId = null),
                ),
                roommatesState.maybeWhen(
                  data: (roommates) => Row(
                    children: roommates
                        .map((r) => Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: _buildWhoPaidChip(
                                name: r.name,
                                isSelected: _quickSplitPayerId == r.id,
                                initials: r.name.isNotEmpty ? r.name[0].toUpperCase() : '?',
                                onTap: () => setState(() => _quickSplitPayerId = r.id),
                              ),
                            ))
                        .toList(),
                  ),
                  orElse: () => const SizedBox(),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _showAddRoommateDialog(context, ref),
                  icon: const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 28),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Add new member',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.s4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pLarge, vertical: AppDimensions.pHuge),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(AppDimensions.r3)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('₹', style: TextStyle(fontSize: 24, color: AppColors.textMuted.withAlpha(125), fontWeight: FontWeight.bold)),
                const SizedBox(width: AppDimensions.s1),
                Expanded(
                  child: TextFormField(
                    controller: _quickSplitAmountController,
                    style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
                    decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero, hintText: '0'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.s3),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(AppDimensions.r3)),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isCustomSplitSelection = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: AppDimensions.s2),
                      decoration: BoxDecoration(
                        color: !_isCustomSplitSelection ? AppColors.surface : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text('Equal Split',
                          style: TextStyle(
                            fontWeight: !_isCustomSplitSelection ? FontWeight.bold : FontWeight.normal,
                            color: !_isCustomSplitSelection ? AppColors.textPrimary : AppColors.textMuted,
                          )),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _isCustomSplitSelection = true;
                        // Pre-populate if empty
                        if (_selectedSplitIds.isEmpty && roommatesState.hasValue) {
                          _selectedSplitIds.add(null);
                          for (var r in roommatesState.value!) {
                            _selectedSplitIds.add(r.id);
                          }
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: AppDimensions.s2),
                      decoration: BoxDecoration(
                        color: _isCustomSplitSelection ? AppColors.surface : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text('Custom Members',
                          style: TextStyle(
                            fontWeight: _isCustomSplitSelection ? FontWeight.bold : FontWeight.normal,
                            color: _isCustomSplitSelection ? AppColors.textPrimary : AppColors.textMuted,
                          )),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isCustomSplitSelection) ...[
            const SizedBox(height: AppDimensions.s3),
            const Text('SELECT MEMBERS FOR SPLIT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppColors.textMuted)),
            const SizedBox(height: AppDimensions.s2),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: [
                  _buildSplitMemberChip(
                    name: 'Me',
                    isSelected: _selectedSplitIds.contains(null),
                    initials: 'M',
                    onTap: () => setState(() {
                      if (_selectedSplitIds.contains(null)) {
                        _selectedSplitIds.remove(null);
                      } else {
                        _selectedSplitIds.add(null);
                      }
                    }),
                  ),
                  roommatesState.maybeWhen(
                    data: (roommates) => Row(
                      children: roommates
                          .map((r) => Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: _buildSplitMemberChip(
                                  name: r.name,
                                  isSelected: _selectedSplitIds.contains(r.id),
                                  initials: r.name.isNotEmpty ? r.name[0].toUpperCase() : '?',
                                  onTap: () => setState(() {
                                    if (_selectedSplitIds.contains(r.id)) {
                                      _selectedSplitIds.remove(r.id);
                                    } else {
                                      _selectedSplitIds.add(r.id);
                                    }
                                  }),
                                ),
                              ))
                          .toList(),
                    ),
                    orElse: () => const SizedBox(),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppDimensions.s4),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _handleQuickSplit,
              borderRadius: BorderRadius.circular(AppDimensions.r3),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(230),
                  borderRadius: BorderRadius.circular(AppDimensions.r3),
                  boxShadow: [BoxShadow(color: AppColors.primary.withAlpha(75), blurRadius: 24, offset: const Offset(0, 8))],
                ),
                alignment: Alignment.center,
                child: const Text('Split with Circle', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.background)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhoPaidChip({required String name, required bool isSelected, required String initials, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(left: 8, top: 8, bottom: 8, right: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface : AppColors.background,
          borderRadius: BorderRadius.circular(AppDimensions.rMax),
          border: Border.all(color: isSelected ? Colors.white.withAlpha(50) : Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: AppColors.primary.withAlpha(50),
              child: Text(initials, style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: AppDimensions.s1),
            Text(name,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? AppColors.textPrimary : AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildSplitMemberChip({required String name, required bool isSelected, required String initials, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withAlpha(40) : AppColors.background,
          borderRadius: BorderRadius.circular(AppDimensions.rMax),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.white.withAlpha(20)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) const Icon(Icons.check_circle, size: 14, color: AppColors.primary),
            if (isSelected) const SizedBox(width: 4),
            Text(name,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.textPrimary : AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
