import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EmailVerificationGate extends StatefulWidget {
  final String title;
  final String description;
  final Widget child;
  final EdgeInsets padding;

  const EmailVerificationGate({
    super.key,
    this.title = "Verify Your Email",
    this.description =
        "Please verify your email address to access this feature.",
    required this.child,
    this.padding = const EdgeInsets.all(32),
  });

  @override
  State<EmailVerificationGate> createState() => _EmailVerificationGateState();
}

class _EmailVerificationGateState extends State<EmailVerificationGate> {
  bool _isRefreshing = false;
  Timer? _timer;
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    if (_user != null && !_user!.emailVerified) {
      _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
        _checkVerificationStatus();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<User?> _reloadCurrentUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return null;

    await currentUser.reload();
    final refreshedUser = FirebaseAuth.instance.currentUser;
    if (refreshedUser != null) {
      await refreshedUser.getIdToken(true);
    }

    return refreshedUser;
  }

  Future<void> _checkVerificationStatus() async {
    final user = await _reloadCurrentUser();
    if (!mounted) return;

    setState(() => _user = user);
    if (user?.emailVerified == true) {
      _timer?.cancel();
    }
  }

  Future<void> _sendVerification(User user) async {
    try {
      await user.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Verification email sent! Check your inbox."),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _refreshStatus(User user) async {
    setState(() => _isRefreshing = true);
    try {
      final updatedUser = await _reloadCurrentUser();
      if (mounted) {
        setState(() => _user = updatedUser);
        if (updatedUser?.emailVerified == true) {
          _timer?.cancel();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Email verified! Unlocking feature..."),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error refreshing: ${e.toString()}"),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _user ?? FirebaseAuth.instance.currentUser;

    if (user == null || !user.emailVerified) {
      return _buildVerifyState(context, user);
    }

    return widget.child;
  }

  Widget _buildVerifyState(BuildContext context, User? user) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        padding: widget.padding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.email_rounded,
                size: 48,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              widget.title,
              style: text.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 24,
                color: colors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              widget.description,
              style: text.bodyMedium?.copyWith(
                color: colors.onSurface.withOpacity(0.6),
                fontSize: 15,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            InkWell(
              onTap: user != null && !_isRefreshing
                  ? () => _sendVerification(user)
                  : null,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.send_rounded, size: 20, color: colors.primary),
                    const SizedBox(width: 10),
                    Text(
                      "Send Verification",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: user != null && !_isRefreshing
                  ? () => _refreshStatus(user)
                  : null,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: colors.surface.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colors.outline.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _isRefreshing
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.primary,
                            ),
                          )
                        : Icon(
                            Icons.refresh_rounded,
                            size: 20,
                            color: colors.primary,
                          ),
                    const SizedBox(width: 10),
                    Text(
                      "I've Verified My Email",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
