import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/colors.dart';

class TermsConsentOverlay extends StatefulWidget {
  final Widget child;
  const TermsConsentOverlay({super.key, required this.child});

  @override
  State<TermsConsentOverlay> createState() => _TermsConsentOverlayState();
}

class _TermsConsentOverlayState extends State<TermsConsentOverlay> {
  bool? _hasAccepted;

  @override
  void initState() {
    super.initState();
    _checkConsent();
  }

  Future<void> _checkConsent() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hasAccepted = prefs.getBool('terms_accepted') ?? false;
    });
  }

  Future<void> _acceptTerms() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('terms_accepted', true);
    setState(() {
      _hasAccepted = true;
    });
  }

  void _refuseTerms() {
    if (kIsWeb) {
      // On web we can't really "close" the app easily, so we show a blocked state
      setState(() {
        _hasAccepted = null; // Represents "Refused" state
      });
    } else {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasAccepted == null) {
      return _buildRefusedState();
    }

    if (_hasAccepted == false) {
      return Stack(
        children: [
          widget.child,
          _buildConsentDialog(),
        ],
      );
    }

    return widget.child;
  }

  Widget _buildConsentDialog() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2128),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white10),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.description_outlined, color: AppColors.primary, size: 32),
              ),
              const SizedBox(height: 24),
              const Text(
                'Terms of Service',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Before you start using Mess Buddy, please review and accept our Terms and Conditions.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _refuseTerms,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Colors.white10),
                        ),
                      ),
                      child: const Text(
                        'Refuse',
                        style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _acceptTerms,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Accept',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRefusedState() {
    return Scaffold(
      backgroundColor: const Color(0xFF111317),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.block_outlined, color: Colors.white24, size: 64),
            const SizedBox(height: 24),
            const Text(
              'Access Restricted',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'You must accept the terms to use this app.',
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 32),
            TextButton(
              onPressed: () => setState(() => _hasAccepted = false),
              child: const Text('Return to Consent', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
  }
}
