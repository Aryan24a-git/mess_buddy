import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mess_buddy/core/theme/colors.dart';
import '../providers/auth_provider.dart';

class WelcomeSignupPage extends ConsumerStatefulWidget {
  const WelcomeSignupPage({super.key});

  @override
  ConsumerState<WelcomeSignupPage> createState() => _WelcomeSignupPageState();
}

class _WelcomeSignupPageState extends ConsumerState<WelcomeSignupPage> {
  bool _busy = false;
  String? _error;
  String? _referralCode;

  Future<void> _googleSignIn() async {
    setState(() { _busy = true; _error = null; });
    try {
      await ref.read(authProvider.notifier).signInWithGoogle(referralCode: _referralCode);
    } catch (e) {
      setState(() { _error = _friendly(e.toString()); });
    } finally {
      if (mounted) setState(() { _busy = false; });
    }
  }

  Future<void> _guestSignIn() async {
    setState(() { _busy = true; _error = null; });
    try {
      await ref.read(authProvider.notifier).signInAnonymously();
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _busy = false; });
    }
  }

  void _emailSignUp() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EmailSignUpSheet(
        initialReferralCode: _referralCode,
        onDone: () {},
      ),
    );
  }

  String _friendly(String raw) {
    if (raw.contains('cancelled') || raw.contains('cancel')) return 'Sign-in was cancelled.';
    if (raw.contains('network-request-failed')) return 'No internet connection.';
    if (raw.contains('operation-not-allowed')) return 'Sign-in method not enabled.';
    if (raw.contains('email-already-in-use')) return 'This email is already registered.';
    return 'Error: $raw';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const _AmbientBackground(),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Image.asset(
                              'assets/images/logo.png',
                              height: 48,
                              width: 48,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Mess Buddy',
                              style: TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -1,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () => context.push('/login'),
                          child: const Text(
                            'Log In',
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.secondary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'PRO EXCHANGE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Headline
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: Theme.of(context).textTheme.displayLarge,
                            children: const [
                              TextSpan(text: 'Effortless '),
                              TextSpan(
                                text: 'Shared',
                                style: TextStyle(color: AppColors.primary),
                              ),
                              TextSpan(text: '\nLiving.'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 40.0),
                          child: Text(
                            'Manage hostel expenses without the headache. Transparent, fast, and fair.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Optional Referral Field
                        Container(
                          width: 280,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.ghostBorder),
                          ),
                          child: TextField(
                            onChanged: (v) => _referralCode = v.trim(),
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: const InputDecoration(
                              hintText: 'Referral Code (Optional)',
                              hintStyle: TextStyle(color: AppColors.textSecondary),
                              border: InputBorder.none,
                              icon: Icon(Icons.card_giftcard, color: AppColors.textSecondary, size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        if (_error != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Buttons
                        Column(
                          children: [
                            _GoogleSignInButton(
                              busy: _busy,
                              onPressed: _googleSignIn,
                            ),
                            const SizedBox(height: 16),
                            _EmailSignupButton(
                              busy: _busy,
                              onPressed: _emailSignUp,
                            ),
                            if (kIsWeb) ...[
                              const SizedBox(height: 16),
                              _GuestAccessButton(
                                busy: _busy,
                                onPressed: _guestSignIn,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Login link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Already have an account? ',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                            GestureDetector(
                              onTap: () => context.push('/login'),
                              child: const Text(
                                'Log In',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          'By continuing, you agree to our\nTerms of Service and Privacy Policy.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmailSignUpSheet extends ConsumerStatefulWidget {
  final String? initialReferralCode;
  final VoidCallback onDone;
  const _EmailSignUpSheet({this.initialReferralCode, required this.onDone});

  @override
  ConsumerState<_EmailSignUpSheet> createState() => _EmailSignUpSheetState();
}

class _EmailSignUpSheetState extends ConsumerState<_EmailSignUpSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _referralCtrl = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialReferralCode != null) {
      _referralCtrl.text = widget.initialReferralCode!;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _referralCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _busy = true; _error = null; });
    try {
      await ref.read(authProvider.notifier).signUpWithEmail(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        name: _nameCtrl.text.trim(),
        referralCode: _referralCtrl.text.trim().isEmpty ? null : _referralCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      setState(() { _error = _friendly(e.toString()); });
    } finally {
      if (mounted) setState(() { _busy = false; });
    }
  }

  String _friendly(String raw) {
    if (raw.contains('email-already-in-use')) return 'Email already in use. Try logging in.';
    if (raw.contains('weak-password')) return 'Password is too weak.';
    if (raw.contains('invalid-email')) return 'Invalid email address.';
    return 'Signup failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1D22),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Create Account',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
              const SizedBox(height: 16),
            ],
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _SheetField(
                    controller: _nameCtrl,
                    label: 'Full Name',
                    icon: Icons.person_outline,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  _SheetField(
                    controller: _emailCtrl,
                    label: 'Email',
                    icon: Icons.email_outlined,
                    validator: (v) => v == null || !v.contains('@') ? 'Invalid email' : null,
                  ),
                  const SizedBox(height: 12),
                  _SheetField(
                    controller: _passCtrl,
                    label: 'Password',
                    icon: Icons.lock_outline,
                    obscure: _obscure,
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    validator: (v) => v == null || v.length < 6 ? 'Too short' : null,
                  ),
                  const SizedBox(height: 12),
                  _SheetField(
                    controller: _referralCtrl,
                    label: 'Referral Code (Optional)',
                    icon: Icons.card_giftcard,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _busy ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                ),
                child: _busy
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Create Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;

  const _SheetField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.validator,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}

class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -100,
          left: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100), child: Container(color: Colors.transparent)),
          ),
        ),
      ],
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  final bool busy;
  final VoidCallback onPressed;
  const _GoogleSignInButton({required this.busy, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: busy ? null : onPressed,
        icon: busy ? const SizedBox.shrink() : const Icon(Icons.login, color: Colors.white),
        label: busy ? const CircularProgressIndicator(color: Colors.white) : const Text('Continue with Google', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        ),
      ),
    );
  }
}

class _EmailSignupButton extends StatelessWidget {
  final bool busy;
  final VoidCallback onPressed;
  const _EmailSignupButton({required this.busy, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: busy ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        ),
        child: const Text('Sign up with Email', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
class _GuestAccessButton extends StatelessWidget {
  final bool busy;
  final VoidCallback onPressed;
  const _GuestAccessButton({required this.busy, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.1),
              Colors.white.withValues(alpha: 0.05),
            ],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: busy ? null : onPressed,
            borderRadius: BorderRadius.circular(100),
            child: Center(
              child: busy
                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bolt_rounded, color: AppColors.secondary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Skip to Web Demo (Guest)',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
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
