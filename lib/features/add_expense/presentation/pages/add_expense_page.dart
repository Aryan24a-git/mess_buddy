import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../../dashboard/domain/models/expense.dart';
import '../../../dashboard/presentation/providers/expenses_provider.dart';
import '../../../roommates/presentation/providers/roommates_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class AddExpensePage extends ConsumerStatefulWidget {
  const AddExpensePage({super.key});

  @override
  ConsumerState<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends ConsumerState<AddExpensePage> {
  String _amount = '';
  String _category = 'Food';
  final TextEditingController _noteController = TextEditingController();
  bool _isSplitEnabled = false; 
  final Set<String> _selectedSplitPartners = {}; // Starts empty - user selects who to split with
  bool _isCustomSplit = false;
  final Map<String, double> _customAmounts = {}; // Key: name, Value: amount
  DateTime _selectedDate = DateTime.now();
  final List<MapEntry<String, double>> _selectedQuickAdds = [];

  void _submitExpense() {
    if (_amount.isEmpty) return;
    
    final parsedAmount = double.tryParse(_amount) ?? 0.0;
    if (parsedAmount <= 0) return;

    String cleanTitle = _noteController.text.isNotEmpty ? _noteController.text : 'Quick Add: $_category';
    
    if (_isSplitEnabled && _selectedSplitPartners.isNotEmpty) {
      final String partnerNote;
      if (_isCustomSplit) {
        partnerNote = 'Custom Split (${_selectedSplitPartners.length} friends)';
      } else {
        partnerNote = _selectedSplitPartners.length > 2 
            ? '${_selectedSplitPartners.first} & ${_selectedSplitPartners.length - 1} others'
            : _selectedSplitPartners.join(', ');
      }
      cleanTitle = '$cleanTitle (Split with $partnerNote)';
    }

    final newExpense = Expense(
      title: cleanTitle,
      amount: parsedAmount,
      payerId: 1, 
      category: _category,
      date: _selectedDate,
      isSplit: _isSplitEnabled && _selectedSplitPartners.isNotEmpty,
      splitWith: _isSplitEnabled ? _selectedSplitPartners.join(', ') : null,
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

      // Ads removed to improve experience

      context.pop();
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
                    const Text('Expense Title', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: AppDimensions.s2),
                    _buildNoteInput(),
                    const SizedBox(height: AppDimensions.s4),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      IconButton(onPressed: () => _showAddCategoryDialog(context), icon: const Icon(Icons.add_circle, color: AppColors.primary), constraints: const BoxConstraints(), padding: EdgeInsets.zero),
                    ]),
                    const SizedBox(height: AppDimensions.s3),
                    _buildCategoriesRow(),
                    const SizedBox(height: AppDimensions.s4),
                    const Text('Quick Add', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: AppDimensions.s3),
                    _buildQuickAddGrid(),
                    const SizedBox(height: AppDimensions.s4),
                    const Text('Date', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: AppDimensions.s2),
                    _buildDateSelector(context),
                    const SizedBox(height: AppDimensions.s3),
                    _buildToggleTile(
                      icon: Icons.people_alt_outlined,
                      title: 'Split with Friends',
                      value: _isSplitEnabled,
                      onChanged: (val) => setState(() => _isSplitEnabled = val),
                    ),
                    if (_isSplitEnabled) ...[
                      const SizedBox(height: AppDimensions.s2),
                      _buildSplitCard(),
                    ],
                    const SizedBox(height: 120),
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
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.close, color: AppColors.textPrimary)),
        const Text('Add Expense', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(width: 48),
      ]),
    );
  }

  Widget _buildAmountInput() {
    return Column(children: [
      const Text('Transaction Amount', style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('₹', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(width: 8),
        IntrinsicWidth(child: TextField(autofocus: true, style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold, color: AppColors.textPrimary), decoration: const InputDecoration(hintText: '0.00', border: InputBorder.none), keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))], onChanged: (v) => setState(() => _amount = v))),
      ]),
      if (_selectedQuickAdds.isNotEmpty) Wrap(spacing: 8, children: _selectedQuickAdds.asMap().entries.map((e) {
        return Chip(label: Text('${e.value.key} (₹${e.value.value.toStringAsFixed(0)})', style: const TextStyle(fontSize: 10)), onDeleted: () {
          setState(() {
            final val = _selectedQuickAdds.removeAt(e.key).value;
            final curr = double.tryParse(_amount) ?? 0.0;
            _amount = (curr - val).toStringAsFixed(2);
            if (_selectedQuickAdds.isEmpty) {
              _noteController.clear();
            }
          });
        });
      }).toList()),
    ]);
  }

  Widget _buildCategoriesRow() {
    final userCats = ref.watch(userCategoriesProvider);
    final limits = ref.watch(budgetLimitsProvider);
    final defaults = {'Food', 'Rent', 'Mess', 'Transport'};
    final cats = <Map<String, dynamic>>[
      {'name': 'Food', 'icon': Icons.restaurant},
      {'name': 'Rent', 'icon': Icons.home},
      {'name': 'Mess', 'icon': Icons.fastfood},
      {'name': 'Transport', 'icon': Icons.directions_bus},
    ];
    
    // Add budget limits
    for (var cat in limits.keys) {
      if (!cats.any((e) => e['name'] == cat)) {
        cats.add({'name': cat, 'icon': Icons.category});
      }
    }

    // Add user persistent categories
    for (var cat in userCats) {
      if (!cats.any((e) => e['name'] == cat)) {
        cats.add({'name': cat, 'icon': Icons.category});
      }
    }
    
    // Ensure currently selected category is shown even if it's custom
    if (!cats.any((e) => e['name'] == _category)) {
      cats.add({'name': _category, 'icon': Icons.category});
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: cats.map((c) {
          final name = c['name'] as String;
          final isS = _category == name;
          final isDefault = defaults.contains(name);

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SizedBox(
              width: 78,  // extra 8px for the X badge
              height: 78, // extra 8px for the X badge
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: GestureDetector(
                      onTap: () => setState(() => _category = name),
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isS ? AppColors.primary : Colors.white10,
                            width: isS ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(c['icon'] as IconData,
                                color: isS ? AppColors.primary : AppColors.textMuted),
                            Text(
                              name,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: isS ? AppColors.primary : AppColors.textMuted),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (!isDefault)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          ref.read(budgetLimitsProvider.notifier).deleteLimits({name});
                          ref.read(userCategoriesProvider.notifier).removeCategory(name);
                          if (_category == name) setState(() => _category = 'Food');
                        },
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 12, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuickAddGrid() {
    final items = ref.watch(quickAddProvider);
    final children = items.entries.map((e) => _buildQuickAddItem(e.key, (e.value['amount'] as num).toDouble(), e.value['category'] as String)).toList();
    children.add(_buildOtherAddTile());
    return GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 2.5, children: children);
  }

  Widget _buildQuickAddItem(String t, double a, String c) {
    return GestureDetector(
      onTap: () => setState(() { 
        _category = c; 
        _selectedQuickAdds.add(MapEntry(t, a)); 
        final curr = double.tryParse(_amount) ?? 0.0; 
        _amount = (curr+a).toStringAsFixed(2); 
        if (_noteController.text.isEmpty) {
          _noteController.text = t; 
        } else if (!_noteController.text.contains(t)) {
          _noteController.text += ', $t'; 
        }
      }),
      child: Container(decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)), child: Padding(padding: const EdgeInsets.all(8.0), child: Row(children: [
        const Icon(Icons.flash_on, color: AppColors.primary, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 1), Text('₹${a.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: Colors.white54))])),
        IconButton(icon: const Icon(Icons.edit, size: 14), onPressed: () => _showEditQuickAddAmount(t, a)),
        IconButton(icon: const Icon(Icons.close, size: 14), onPressed: () => ref.read(quickAddProvider.notifier).removeItem(t)),
      ]),
    )));
  }

  Widget _buildOtherAddTile() {
    return GestureDetector(onTap: _showCreateQuickAddDialog, child: Container(decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)), child: const Center(child: Text('+ Add New', style: TextStyle(color: Colors.white54)))));
  }

  Widget _buildNoteInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16), 
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)), 
      child: TextField(
        controller: _noteController, 
        style: const TextStyle(color: Colors.white), 
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s,]'))],
        decoration: const InputDecoration(hintText: 'Title...', border: InputBorder.none)
      )
    );
  }

  Widget _buildDateSelector(BuildContext context) {
    return GestureDetector(onTap: () async { final d = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2000), lastDate: DateTime(2101)); if (d != null) setState(() => _selectedDate = d); }, child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}', style: const TextStyle(color: Colors.white)), const Icon(Icons.calendar_today, size: 18)])));
  }

  Widget _buildToggleTile({required IconData icon, required String title, required bool value, required Function(bool) onChanged}) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(children: [Icon(icon, color: Colors.white24, size: 20), const SizedBox(width: 8), Text(title, style: const TextStyle(color: Colors.white))]), Switch(value: value, onChanged: onChanged, activeThumbColor: AppColors.primary)]));
  }

  Widget _buildSplitCard() {
    final roommatesState = ref.watch(roommatesProvider);
    final List<Map<String, dynamic>> friendsList = [];
    // Seed from profile's room/hostel if available
    final authData = ref.watch(authProvider).value;
    final profile = authData?.profile;
    if (profile?.roomNo != null && profile!.roomNo!.isNotEmpty) {
      friendsList.add({'name': 'Room ${profile.roomNo}', 'id': null});
    }
    roommatesState.whenData((list) { 
      for (var r in list) {
        if (!friendsList.any((e) => e['name'] == r.name)) {
          friendsList.add({'name': r.name, 'id': r.id});
        }
      }
    });
    final double total = double.tryParse(_amount) ?? 0.0;
    final eachShare = total / (_selectedSplitPartners.length + 1);
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)), child: Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Split Details', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), GestureDetector(onTap: () => _showSplitPartnerPicker(friendsList), child: Text(_selectedSplitPartners.isEmpty ? 'Select Friends' : _selectedSplitPartners.join(', '), style: const TextStyle(fontSize: 12, color: Colors.cyanAccent, decoration: TextDecoration.underline)))]),
        Row(children: [_buildToggleItem('EQUAL', !_isCustomSplit), const SizedBox(width: 8), _buildToggleItem('CUSTOM', _isCustomSplit)]),
      ]),
      const SizedBox(height: 16),
      if (!_isCustomSplit) 
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Wrap(spacing: 8, children: [ 
            _buildMiniAvatar('M', AppColors.primary), 
            ..._selectedSplitPartners.map((n) => _buildMiniAvatar(n[0], Colors.orangeAccent)) 
          ]),
          Text('Each: ₹${eachShare.toStringAsFixed(2)}', style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
        ]) 
      else 
        Column(children: ['Me', ..._selectedSplitPartners].map((n) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
          _buildMiniAvatar(n[0], n == 'Me' ? AppColors.primary : Colors.orangeAccent), 
          const SizedBox(width: 12), 
          Text(n, style: const TextStyle(color: Colors.white)), 
          const Spacer(), 
          SizedBox(width: 80, child: TextField(keyboardType: TextInputType.number, style: const TextStyle(color: Colors.cyanAccent), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))], decoration: const InputDecoration(prefixText: '₹'), onChanged: (v) => _customAmounts[n] = double.tryParse(v) ?? 0))
        ]))).toList()),
    ]));
  }

  Widget _buildToggleItem(String l, bool a) => GestureDetector(onTap: () => setState(() => _isCustomSplit = l == 'CUSTOM'), child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: a ? AppColors.primary.withValues(alpha: 0.2) : Colors.transparent, borderRadius: BorderRadius.circular(20), border: Border.all(color: a ? AppColors.primary : Colors.white10)), child: Text(l, style: TextStyle(fontSize: 10, color: a ? AppColors.primary : Colors.white54))));

  void _showSplitPartnerPicker(List<Map<String, dynamic>> friends) {
    showModalBottomSheet(context: context, backgroundColor: AppColors.surface, builder: (ctx) => StatefulBuilder(builder: (c, setS) => Container(padding: const EdgeInsets.all(16), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ const Text('Split With', style: TextStyle(fontSize: 18, color: Colors.white)), TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Confirm')) ]),
      ...friends.map((f) => Row(children: [
        Checkbox(value: _selectedSplitPartners.contains(f['name']), onChanged: (v) => setState(() { 
          if (v!) {
            _selectedSplitPartners.add(f['name'] as String); 
          } else {
            _selectedSplitPartners.remove(f['name'] as String); 
          }
          setS((){}); 
        })),
        Text(f['name'] as String, style: const TextStyle(color: Colors.white)),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.redAccent), 
          onPressed: () {
            setState(() { 
              _selectedSplitPartners.remove(f['name']); 
              if (f['id'] != null) {
                ref.read(roommatesProvider.notifier).deleteRoommate(f['id'] as int);
              }
              friends.remove(f); 
              setS((){}); 
            });
          },
        ),
      ])),
      const Divider(color: Colors.white10),
      ListTile(
        leading: const Icon(Icons.person_add_alt_1, color: AppColors.primary),
        title: const Text('Add New Roommate/Friend', style: TextStyle(color: AppColors.primary)),
        onTap: () {
          final nameCtrl = TextEditingController();
          final phoneCtrl = TextEditingController();
          showDialog(
            context: ctx,
            builder: (dCtx) => AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text('Add Friend', style: TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))],
                    decoration: const InputDecoration(
                      hintText: 'Name',
                      hintStyle: TextStyle(color: Colors.white38),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: phoneCtrl,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      hintText: 'Phone (optional)',
                      hintStyle: TextStyle(color: Colors.white38),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancel')),
                TextButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    if (name.isNotEmpty) {
                      await ref.read(roommatesProvider.notifier).addRoommate(name, phoneCtrl.text.trim());
                      if (!friends.any((e) => e['name'] == name)) {
                        friends.add({'name': name, 'id': null});
                      }
                      setState(() => _selectedSplitPartners.add(name));
                      setS(() {});
                    }
                    if (dCtx.mounted) Navigator.pop(dCtx);
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
          );
        },
      ),
    ]))));
  }

  Widget _buildPrimaryButton() => ElevatedButton(onPressed: _submitExpense, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)), child: const Text('Add Expense', style: TextStyle(color: Colors.white)));

  void _showAddCategoryDialog(BuildContext context) {
    final c = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Add Custom Category', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: c,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))],
          decoration: const InputDecoration(
            hintText: 'Enter name...',
            hintStyle: TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final catName = c.text.trim();
              if (catName.isNotEmpty) {
                try {
                  await ref.read(userCategoriesProvider.notifier).addCategory(catName);
                  setState(() => _category = catName);
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Category added successfully!'), backgroundColor: AppColors.success),
                    );
                    Navigator.pop(ctx);
                  }
                } catch (e) {
                   if (ctx.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppColors.error),
                    );
                  }
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
  
  void _showEditQuickAddAmount(String t, double a) {
    final c = TextEditingController(text: a.toStringAsFixed(0));
    showDialog(context: context, builder: (ctx) => AlertDialog(backgroundColor: AppColors.surface, title: Text('Edit $t'), content: TextField(controller: c, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))]), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), TextButton(onPressed: () { 
      final v = double.tryParse(c.text); 
      if (v != null) {
        ref.read(quickAddProvider.notifier).editAmount(t, v); 
      }
      Navigator.pop(ctx); 
    }, child: const Text('Save'))]));
  }

  void _showCreateQuickAddDialog() {
    final t = TextEditingController(); final a = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(backgroundColor: AppColors.surface, title: const Text('New Quick Add'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: t, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'Item Name')), TextField(controller: a, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'Amount'))]), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), TextButton(onPressed: () { 
      final v = double.tryParse(a.text); 
      if (t.text.isNotEmpty && v != null) {
        ref.read(quickAddProvider.notifier).addItem(t.text, v, 'Food'); 
      }
      Navigator.pop(ctx); 
    }, child: const Text('Create'))]));
  }

  Widget _buildMiniAvatar(String text, Color color) {
    return CircleAvatar(radius: 12, backgroundColor: color, child: Text(text, style: const TextStyle(fontSize: 10, color: Colors.white)));
  }
}
