import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../../../core/theme/colors.dart';
import '../../domain/user_profile.dart';
import '../../../../core/utils/referral_utils.dart';
import '../providers/auth_provider.dart';

/// First-launch screen or Edit screen: collect name, budget, profile pic, and optional hostel info.
class ProfileSetupPage extends ConsumerStatefulWidget {
  final bool isEditing;
  const ProfileSetupPage({super.key, this.isEditing = false});

  @override
  ConsumerState<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends ConsumerState<ProfileSetupPage>
    with SingleTickerProviderStateMixin {
  final _formKey      = GlobalKey<FormState>();
  final _nameCtrl     = TextEditingController();
  final _budgetCtrl   = TextEditingController();
  final _roomCtrl     = TextEditingController();
  final _hostelCtrl   = TextEditingController();
  final _roommateCtrl = TextEditingController();
  
  String? _profilePicData; // This will store either the local file path (mobile) or base64 (web)
  Uint8List? _webImageBytes; // For immediate preview on web
  bool _isLoading = false;

  late AnimationController _animCtrl;
  late Animation<double>   _fadeIn;
  late Animation<Offset>   _slideUp;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeIn  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();

    // Pre-fill if editing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authData = ref.read(authProvider).value;
      final profile = authData?.profile;
      if (profile != null) {
        _nameCtrl.text = profile.name;
        _budgetCtrl.text = profile.monthlyBudget > 0 ? profile.monthlyBudget.toStringAsFixed(0) : '';
        _roomCtrl.text = profile.roomNo ?? '';
        _hostelCtrl.text = profile.hostelName ?? '';
        _roommateCtrl.text = profile.roommateName ?? '';
        setState(() {
          _profilePicData = profile.profilePicPath;
          if (kIsWeb && _profilePicData != null && _profilePicData!.startsWith('data:image')) {
            // Already base64, we don't need to rebuild bytes for NetworkImage(base64)
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameCtrl.dispose();
    _budgetCtrl.dispose();
    _roomCtrl.dispose();
    _hostelCtrl.dispose();
    _roommateCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery, 
        imageQuality: 50, // Reduced quality for smaller base64 on web
        maxWidth: 500,    // Caps resolution for profile pics
        maxHeight: 500,
      );
      
      if (image != null) {
        final size = await image.length();
        const maxSize = 5 * 1024 * 1024; // 5MB in bytes

        if (size > maxSize) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile picture must be under 5MB'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return;
        }

        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          // Convert to base64 for persistent storage on web (since blob URLs die on reload)
          final base64String = 'data:image/${p.extension(image.path).replaceAll('.', '')};base64,${base64Encode(bytes)}';
          setState(() {
            _webImageBytes = bytes;
            _profilePicData = base64String;
          });
        } else {
          // Save to app directory to ensure persistence on mobile/windows
          final appDir = await getApplicationDocumentsDirectory();
          final fileName = 'profile_pic_${DateTime.now().millisecondsSinceEpoch}${p.extension(image.path)}';
          final localImage = await File(image.path).copy('${appDir.path}/$fileName');
          setState(() => _profilePicData = localImage.path);
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final authData = ref.read(authProvider).value;
    final existingProfile = authData?.profile;

    // Generate code only if it doesn't exist
    final referralCode = existingProfile?.referralCode ?? ReferralUtils.generateCode();

    final profile = UserProfile(
      name:         _nameCtrl.text.trim(),
      email:        existingProfile?.email ?? '', // Preserve email
      monthlyBudget: double.tryParse(_budgetCtrl.text.trim()) ?? 0,
      roomNo:       _roomCtrl.text.trim().isEmpty     ? null : _roomCtrl.text.trim(),
      hostelName:   _hostelCtrl.text.trim().isEmpty   ? null : _hostelCtrl.text.trim(),
      roommateName: _roommateCtrl.text.trim().isEmpty ? null : _roommateCtrl.text.trim(),
      profilePicPath: _profilePicData,
      referralCode: referralCode, // Set the unique code
    );

    await ref.read(authProvider.notifier).setupProfile(profile);
    if (mounted) {
      setState(() => _isLoading = false);
      if (widget.isEditing) {
        context.pop();
      } else {
        context.go('/');
      }
    }
  }

  ImageProvider? _getImageProvider() {
    if (_profilePicData == null) return null;

    if (kIsWeb) {
      if (_webImageBytes != null) {
        return MemoryImage(_webImageBytes!);
      }
      if (_profilePicData!.startsWith('data:image')) {
        // Handle base64 string
        final base64Content = _profilePicData!.split(',').last;
        return MemoryImage(base64Decode(base64Content));
      }
      return NetworkImage(_profilePicData!);
    } else {
      return FileImage(File(_profilePicData!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleText = widget.isEditing ? 'Edit Your Profile' : 'Set Up Your Profile';
    final buttonText = widget.isEditing ? 'Save Changes' : 'Start Using Mess Buddy';

    return Scaffold(
      backgroundColor: const Color(0xFF111317),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: SlideTransition(
            position: _slideUp,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (widget.isEditing)
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => context.pop(),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: const Text('Mess Buddy',
                                style: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
                          ),
                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(titleText,
                              style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 8),
                          const Text(
                            'Keep your hostel profile up to date.',
                            style: TextStyle(fontSize: 14, color: AppColors.textMuted, height: 1.5),
                          ),
                          const SizedBox(height: 32),

                          // Avatar with Image Picker
                          Center(
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Stack(clipBehavior: Clip.none, children: [
                                Container(
                                  width: 100, height: 100,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2A2D33),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
                                    image: _profilePicData != null
                                        ? DecorationImage(
                                            image: _getImageProvider()!,
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: _profilePicData == null 
                                      ? const Icon(Icons.person, size: 50, color: AppColors.textMuted)
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0, right: 0,
                                  child: Container(
                                    width: 34, height: 34,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFF111317), width: 3),
                                    ),
                                    child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                                  ),
                                ),
                              ]),
                            ),
                          ),
                          const SizedBox(height: 36),

                          _label('Full Name', required: true),
                          const SizedBox(height: 8),
                          _field(
                            controller: _nameCtrl, 
                            hint: 'EX-Aryan',
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))],
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Full name is required' : null,
                          ),

                          const SizedBox(height: 20),
                          _label('Monthly Budget', required: true),
                          const SizedBox(height: 8),
                          _field(
                            controller: _budgetCtrl,
                            hint: 'EX-5000',
                            prefix: '₹  ',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Monthly budget is required';
                              if (double.tryParse(v.trim()) == null) return 'Enter a valid number';
                              return null;
                            },
                          ),

                          const SizedBox(height: 28),
                          _sectionDivider('Optional Details'),

                          const SizedBox(height: 20),
                          _label('Room Number', optional: true),
                          const SizedBox(height: 8),
                          _field(controller: _roomCtrl, hint: 'EX-103'),

                          const SizedBox(height: 20),
                          _label('Hostel Name', optional: true),
                          const SizedBox(height: 8),
                          _field(
                            controller: _hostelCtrl, 
                            hint: 'EX-CHANDIDAS CHATRABAS BOYS HOSTEL',
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))],
                          ),

                          const SizedBox(height: 20),
                          _label('Roommate Names', optional: true),
                          const SizedBox(height: 8),
                          _field(
                            controller: _roommateCtrl, 
                            hint: 'EX-Olive, Aritra, Sagar',
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s,]'))],
                          ),

                          const SizedBox(height: 40),

                          SizedBox(
                            width: double.infinity,
                            height: 58,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                                elevation: 0,
                              ),
                              onPressed: _isLoading ? null : _submit,
                              child: _isLoading
                                  ? const SizedBox(width: 22, height: 22,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(buttonText,
                                            style: const TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1C20))),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.check_circle_outline, size: 18, color: Color(0xFF1A1C20)),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 36),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text, {bool required = false, bool optional = false}) {
    return Row(children: [
      Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
      if (required) const Text(' *', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
      if (optional) const Text('  OPTIONAL', style: TextStyle(fontSize: 10, color: AppColors.textMuted, letterSpacing: 0.8)),
    ]);
  }

  Widget _sectionDivider(String label) {
    return Row(children: [
      Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.07))),
      const SizedBox(width: 10),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, letterSpacing: 0.5)),
      const SizedBox(width: 10),
      Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.07))),
    ]);
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? prefix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        prefixText: prefix,
        prefixStyle: const TextStyle(color: AppColors.textMuted, fontSize: 15),
        hintStyle: const TextStyle(color: AppColors.textMuted),
        filled: true,
        fillColor: const Color(0xFF1E2128),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border:       OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.5), width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.error, width: 1)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
        errorStyle: const TextStyle(color: AppColors.error, fontSize: 11),
      ),
    );
  }
}
