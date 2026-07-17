import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../providers/launch_settings_provider.dart';
import '../router/app_router.dart';
import '../theme/app_colors.dart';

/// Real Room screen, ported from RoomActivity.kt.
///
/// No direct WhatsApp equivalent — WhatsApp doesn't have "rooms," just a
/// chat list. This screen keeps its original Kotlin shape (signed-in-as
/// card, create-room card, join-room card) restyled with KilatSpeak's
/// navy/gold/cream identity. The WhatsApp-inspired layout direction
/// applies to the Contacts tab (Phase 7) and the Recording/Chat screen
/// (Phase 9) instead, where it's actually relevant.
class RoomScreen extends ConsumerStatefulWidget {
  const RoomScreen({super.key});

  @override
  ConsumerState<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends ConsumerState<RoomScreen> {
  final _joinCodeController = TextEditingController();
  String? _generatedRoomCode;
  bool _isSigningOut = false;

  static const _roomCodeLength = 5;
  static const _roomCodeChars = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

  @override
  void dispose() {
    _joinCodeController.dispose();
    super.dispose();
  }

  /// Generates a 5-character alphanumeric room code using only
  /// unambiguous characters (no 0/O, 1/I/L pairs) — identical character
  /// set and logic to RoomActivity.kt's generateRoomCode().
  String _generateRoomCode() {
    final random = Random.secure();
    return List.generate(
      _roomCodeLength,
      (_) => _roomCodeChars[random.nextInt(_roomCodeChars.length)],
    ).join();
  }

  void _handleCreateRoom() {
    setState(() => _generatedRoomCode = _generateRoomCode());
  }

  void _handleEnterRoom() {
    if (_generatedRoomCode == null) return;
    _navigateToRecording(_generatedRoomCode!);
  }

  void _handleJoinRoom() {
    final code = _joinCodeController.text.trim().toUpperCase();
    if (code.length != _roomCodeLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Room code must be $_roomCodeLength characters.')),
      );
      return;
    }
    _navigateToRecording(code);
  }

  void _navigateToRecording(String roomCode) {
    final settingsAsync = ref.read(launchSettingsProvider);
    final myLanguage = settingsAsync.value?.myLanguage;
    if (myLanguage == null) return; // settings not loaded yet — shouldn't happen post-Launch

    context.push(
      AppRoutes.recording,
      extra: {
        'roomCode': roomCode,
        'myLanguage': myLanguage,
      },
    );
  }

  Future<void> _handleSignOut() async {
    setState(() => _isSigningOut = true);
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {
      // Non-fatal — proceed to clear Google session and navigate regardless.
    }
    try {
      // disconnect() (not just signOut()) fully resets the Google session
      // so the account picker shows again next time, matching the Kotlin
      // app's explicit googleSignInClient.signOut() call on RoomActivity's
      // sign-out handler. Wrapped in try/catch: known to throw if there's
      // no active Google session to disconnect.
      await GoogleSignIn.instance.disconnect();
    } catch (_) {
      // Safe to ignore — see comment above.
    }
    if (!mounted) return;
    setState(() => _isSigningOut = false);
    context.go(AppRoutes.auth);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!
        : 'User';

    return Scaffold(
      backgroundColor: AppColors.creamBg,
      appBar: AppBar(
        title: const Text('KilatSpeak'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSignedInCard(displayName),
              const SizedBox(height: 20),
              _buildSectionDivider('START A NEW ROOM'),
              const SizedBox(height: 16),
              _buildCreateRoomCard(),
              const SizedBox(height: 20),
              _buildSectionDivider('OR JOIN AN EXISTING ROOM'),
              const SizedBox(height: 16),
              _buildJoinRoomCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignedInCard(String displayName) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SIGNED IN AS',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            _isSigningOut
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton(
                    onPressed: _handleSignOut,
                    child: const Text(
                      'Sign Out',
                      style: TextStyle(color: AppColors.recordingRed),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionDivider(String label) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.divider)),
      ],
    );
  }

  Widget _buildCreateRoomCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Share this code with your partner so they can join your room.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.goldPale),
              child: Text(
                _generatedRoomCode ?? '– – – – –',
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navyDeep,
                  fontFamily: 'monospace',
                  letterSpacing: 4,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _handleCreateRoom,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.goldPrimary,
                foregroundColor: AppColors.navyDeep,
                minimumSize: const Size(double.infinity, 52),
              ),
              child: const Text('Generate Room Code'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _generatedRoomCode == null ? null : _handleEnterRoom,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navyDeep,
                foregroundColor: AppColors.creamCard,
                disabledBackgroundColor: AppColors.divider,
                minimumSize: const Size(double.infinity, 52),
              ),
              child: const Text('Enter Room'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinRoomCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ROOM CODE',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _joinCodeController,
              textCapitalization: TextCapitalization.characters,
              maxLength: _roomCodeLength,
              style: const TextStyle(
                fontSize: 22,
                fontFamily: 'monospace',
                letterSpacing: 2,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Enter $_roomCodeLength-character code',
                hintStyle: const TextStyle(color: AppColors.textHint),
                counterText: '',
                border: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.divider),
                ),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.divider),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.navyDeep, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _handleJoinRoom,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.goldPrimary,
                foregroundColor: AppColors.navyDeep,
                minimumSize: const Size(double.infinity, 52),
              ),
              child: const Text('Join Room'),
            ),
          ],
        ),
      ),
    );
  }
}
