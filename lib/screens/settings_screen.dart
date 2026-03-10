import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../utils/toast.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = '...';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _appVersion = '${info.version} (${info.buildNumber})');
  }

  User? get _user => FirebaseAuth.instance.currentUser;

  bool get _isGoogleUser =>
      _user?.providerData.any((p) => p.providerId == 'google.com') ?? false;

  // ── EDIT DISPLAY NAME ─────────────────────────────────────────────────────
  Future<void> _editDisplayName() async {
    final controller = TextEditingController(text: _user?.displayName ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1F2D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Name',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          cursorColor: Color(0xFFFFD700),
          decoration: InputDecoration(
            hintText: 'Your name',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Colors.white.withOpacity(0.07),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Save', style: TextStyle(color: Color(0xFFFFD700))),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await _user?.updateDisplayName(result);
      setState(() {});
      if (mounted) {
        showToast(context,
            message: 'Name\nUpdated!', type: ToastType.success, icon: Icons.person);
      }
    }
  }

  // ── CHANGE EMAIL ──────────────────────────────────────────────────────────
  Future<void> _changeEmail() async {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1F2D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.email_outlined, color: Color(0xFFFFD700)),
          SizedBox(width: 10),
          Text('Change Email', style: TextStyle(color: Colors.white, fontSize: 18)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogField(emailCtrl, 'New email address', Icons.email_outlined),
            const SizedBox(height: 10),
            _dialogField(passCtrl, 'Current password', Icons.lock_outline,
                obscure: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Update', style: TextStyle(color: Color(0xFFFFD700))),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Re-authenticate first
        final cred = EmailAuthProvider.credential(
          email: _user!.email!,
          password: passCtrl.text,
        );
        await _user!.reauthenticateWithCredential(cred);
        await _user!.verifyBeforeUpdateEmail(emailCtrl.text.trim());
        if (mounted) {
          showToast(context,
              message: 'Verification sent\nto new email',
              type: ToastType.success,
              icon: Icons.mark_email_read_outlined);
        }
      } catch (e) {
        if (mounted) {
          showToast(context,
              message: 'Failed!\nCheck credentials',
              type: ToastType.error,
              icon: Icons.error_outline);
        }
      }
    }
  }

  // ── RESET PASSWORD ────────────────────────────────────────────────────────
  Future<void> _resetPassword() async {
    final email = _user?.email;
    if (email == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1F2D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.lock_reset, color: Color(0xFFFFD700)),
          SizedBox(width: 10),
          Text('Reset Password', style: TextStyle(color: Colors.white, fontSize: 18)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('A reset link will be sent to:',
                style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.email_outlined, color: Colors.white54, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(email,
                        style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Send Link', style: TextStyle(color: Color(0xFFFFD700))),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        showToast(context,
            message: 'Reset link\nsent!',
            type: ToastType.success,
            icon: Icons.mark_email_read_outlined);
      }
    }
  }

  // ── SEND EMAIL VERIFICATION ───────────────────────────────────────────────
  Future<void> _sendVerification() async {
    await _user?.sendEmailVerification();
    if (mounted) {
      showToast(context,
          message: 'Verification\nemail sent!',
          type: ToastType.success,
          icon: Icons.mark_email_read_outlined);
    }
  }

  // ── DELETE ACCOUNT ────────────────────────────────────────────────────────
  Future<void> _deleteAccount() async {
    final passCtrl = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1F2D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.delete_forever, color: Colors.redAccent),
          SizedBox(width: 10),
          Text('Delete Account', style: TextStyle(color: Colors.white, fontSize: 18)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will permanently delete your account and ALL your transaction data. This cannot be undone.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 12),
            if (!_isGoogleUser) ...[
              const Text('Enter your password to confirm:',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 8),
              _dialogField(passCtrl, 'Password', Icons.lock_outline, obscure: true),
              const SizedBox(height: 10),
            ],
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('All data will be lost forever.',
                        style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.delete_forever, color: Colors.white, size: 16),
            label: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        if (!_isGoogleUser && passCtrl.text.isNotEmpty) {
          final cred = EmailAuthProvider.credential(
            email: _user!.email!,
            password: passCtrl.text,
          );
          await _user!.reauthenticateWithCredential(cred);
        }
        await _user?.delete();
      } catch (e) {
        if (mounted) {
          showToast(context,
              message: 'Re-login required\nbefore deleting',
              type: ToastType.error,
              icon: Icons.error_outline);
        }
      }
    }
  }

  // ── SIGN OUT ──────────────────────────────────────────────────────────────
  Future<void> _logout() async {
    HapticFeedback.mediumImpact();
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1F2D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.logout, color: Colors.redAccent, size: 24),
          SizedBox(width: 10),
          Text('Sign Out',
              style: TextStyle(color: Color(0xFFFFD700), fontSize: 20)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Are you sure you want to sign out?',
                style: TextStyle(color: Colors.white, fontSize: 15)),
            SizedBox(height: 8),
            Text(
              'Your data is safely stored in the cloud. You can sign back in anytime.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(ctx, false);
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.heavyImpact();
              Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.logout, color: Colors.white, size: 16),
            label: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
    }
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Settings',
            style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
            ),
          ),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A1628), Color(0xFF0D2137), Color(0xFF0A1F1A)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // ── PROFILE CARD ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1F2D),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFF1B5E20),
                    backgroundImage: _user?.photoURL != null
                        ? NetworkImage(_user!.photoURL!)
                        : null,
                    child: _user?.photoURL == null
                        ? Text(
                            (_user?.displayName ?? _user?.email ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(
                                color: Color(0xFFFFD700),
                                fontSize: 24,
                                fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _user?.displayName ?? 'No name set',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(_user?.email ?? '',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 13)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _isGoogleUser
                                ? Colors.blue.withOpacity(0.15)
                                : Colors.green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _isGoogleUser ? 'Google Account' : 'Email Account',
                            style: TextStyle(
                              color: _isGoogleUser
                                  ? Colors.blue.shade300
                                  : Colors.greenAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── ACCOUNT ──────────────────────────────────────────────────
            _sectionLabel('Account'),
            const SizedBox(height: 8),

            _tile(
              icon: Icons.badge_outlined,
              iconColor: Colors.purple,
              title: 'Display Name',
              subtitle: _user?.displayName?.isNotEmpty == true
                  ? _user!.displayName!
                  : 'Tap to set your name',
              onTap: _editDisplayName,
            ),

            const SizedBox(height: 8),

            if (!_isGoogleUser) ...[
              _tile(
                icon: Icons.email_outlined,
                iconColor: Colors.orange,
                title: 'Change Email',
                subtitle: _user?.email ?? '',
                onTap: _changeEmail,
              ),
              const SizedBox(height: 8),
              _tile(
                icon: Icons.lock_reset,
                iconColor: Colors.blue,
                title: 'Reset Password',
                subtitle: 'Send a reset link to your email',
                onTap: _resetPassword,
              ),
              const SizedBox(height: 8),
            ],

            _tile(
              icon: _user?.emailVerified == true
                  ? Icons.verified_user
                  : Icons.gpp_bad_outlined,
              iconColor: _user?.emailVerified == true
                  ? Colors.greenAccent
                  : Colors.amber,
              title: 'Email Verification',
              subtitle: _user?.emailVerified == true
                  ? '✓ Your email is verified'
                  : 'Not verified — tap to send link',
              onTap: _user?.emailVerified == true ? null : _sendVerification,
            ),

            const SizedBox(height: 24),

            // ── DATA ──────────────────────────────────────────────────────
            _sectionLabel('Data'),
            const SizedBox(height: 8),

            _tile(
              icon: Icons.cloud_sync_outlined,
              iconColor: Colors.teal,
              title: 'Cloud Sync',
              subtitle: 'All data is synced to Firebase in real-time',
              onTap: () {
                showToast(context,
                    message: 'Syncing\nNow...',
                    type: ToastType.success,
                    icon: Icons.cloud_sync_outlined);
                FirebaseAuth.instance.currentUser?.reload();
              },
            ),

            const SizedBox(height: 24),

            // ── ABOUT ─────────────────────────────────────────────────────
            _sectionLabel('About'),
            const SizedBox(height: 8),

            _tile(
              icon: Icons.info_outline,
              iconColor: Colors.white54,
              title: 'App Version',
              subtitle: _appVersion,
              onTap: () {
                HapticFeedback.lightImpact();
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: const Color(0xFF0D1F2D),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    title: const Text('FinTrack',
                        style: TextStyle(
                            color: Color(0xFFFFD700),
                            fontWeight: FontWeight.bold)),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Version: $_appVersion',
                            style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 8),
                        const Text('Built with Flutter & Firebase',
                            style: TextStyle(color: Colors.white54, fontSize: 13)),
                        const SizedBox(height: 4),
                        const Text('© 2025 FinTrack',
                            style: TextStyle(color: Colors.white38, fontSize: 12)),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Close',
                            style: TextStyle(color: Color(0xFFFFD700))),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // ── DANGER ZONE ───────────────────────────────────────────────
            _sectionLabel('Danger Zone'),
            const SizedBox(height: 8),

            _tile(
              icon: Icons.delete_forever_outlined,
              iconColor: Colors.redAccent,
              title: 'Delete Account',
              subtitle: 'Permanently delete your account and all data',
              isDestructive: true,
              onTap: _deleteAccount,
            ),

            const SizedBox(height: 8),

            _tile(
              icon: Icons.logout,
              iconColor: Colors.redAccent,
              title: 'Sign Out',
              subtitle: 'You can sign back in anytime',
              isDestructive: true,
              onTap: _logout,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── HELPERS ───────────────────────────────────────────────────────────────
  Widget _sectionLabel(String label) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFFFFD700),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      );

  Widget _tile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap != null
          ? () {
              HapticFeedback.lightImpact();
              onTap();
            }
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDestructive
              ? Colors.red.withOpacity(0.08)
              : const Color(0xFF0D1F2D),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDestructive
                ? Colors.red.withOpacity(0.25)
                : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: isDestructive ? Colors.redAccent : Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right,
                  color: isDestructive
                      ? Colors.redAccent.withOpacity(0.5)
                      : Colors.white24,
                  size: 20),
          ],
        ),
      ),
    );
  }

  Widget _dialogField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      cursorColor: const Color(0xFFFFD700),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: Colors.white38, size: 18),
        filled: true,
        fillColor: Colors.white.withOpacity(0.07),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      ),
    );
  }
}
