import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/token_service.dart';
import '../../models/account_model.dart';
import '../repositories/auth_repository.dart';
import '../repositories/user_repository.dart';
import 'settings_provider.dart';

class AccountsNotifier extends StateNotifier<List<AccountModel>> {
  AccountsNotifier()
    : super([
        const AccountModel(
          id: 'loading',
          name: 'User',
          email: '',
          avatarColor: Color(0xFF195BAC),
          isActive: true,
        ),
      ]) {
    loadMailboxes();
  }

  Future<void> syncWithUser({
    required String email,
    required String name,
    String? avatarUrl,
    String? accountType,
    num? storageUsed,
    num? storageLimit,
    String? token,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) return;

    if (!mounted) return;
    final existingIndex = state.indexWhere(
      (a) => a.email.trim().toLowerCase() == cleanEmail,
    );

    if (existingIndex >= 0) {
      final old = state[existingIndex];
      final updated = old.copyWith(
        name: name.isNotEmpty ? name : old.name,
        avatarUrl: avatarUrl ?? old.avatarUrl,
        accountType: accountType ?? old.accountType,
        storageUsed: storageUsed ?? old.storageUsed,
        storageLimit: storageLimit ?? old.storageLimit,
        isActive: true,
      );
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == existingIndex) updated else state[i].copyWith(isActive: false),
      ];
    } else {
      final newAcc = AccountModel(
        id: cleanEmail,
        name: name.isNotEmpty ? name : cleanEmail.split('@').first,
        email: cleanEmail,
        avatarColor: const Color(0xFF195BAC),
        isActive: true,
        avatarUrl: avatarUrl,
        accountType: accountType ?? 'BUSINESS',
        storageUsed: storageUsed,
        storageLimit: storageLimit,
      );
      final withoutDummies = state
          .where((a) => a.id != 'loading')
          .map((a) => a.copyWith(isActive: false))
          .toList();
      state = [newAcc, ...withoutDummies];
    }

    if (token != null && token.isNotEmpty) {
      await TokenService.syncWithAuth(
        token: token,
        email: cleanEmail,
        name: name,
        avatarUrl: avatarUrl,
      );
    } else {
      await TokenService.saveUserInfo(email: cleanEmail, name: name);
      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        await TokenService.saveUserAvatar(cleanEmail, avatarUrl);
      }
    }
  }

  Future<void> loadMailboxes([String? forceActiveEmail]) async {
    final activeAccountEmail = state
        .firstWhere((a) => a.isActive && a.id != 'loading',
            orElse: () => const AccountModel(
                id: '', name: '', email: '', avatarColor: Color(0xFF195BAC)))
        .email
        .trim()
        .toLowerCase();

    final loggedInEmail = forceActiveEmail?.trim().toLowerCase() ??
        (activeAccountEmail.isNotEmpty
            ? activeAccountEmail
            : (await TokenService.getUserEmail() ?? '')
                .trim()
                .toLowerCase());
    final savedRegistry = await TokenService.getSavedAccountsFromRegistry();
    final userProfile = await UserRepository.getProfile();

    List<AccountModel> mergedList = [];

    // 1. Build accounts from saved local registry
    for (final reg in savedRegistry) {
      final regEmail = (reg['email']?.toString() ?? '').trim().toLowerCase();
      if (regEmail.isEmpty) continue;
      final regName = reg['name']?.toString() ?? regEmail.split('@').first;
      final savedAvatar = await TokenService.getUserAvatar(regEmail);
      final cachedSettings = await TokenService.getUserSettings(regEmail) ?? {};

      final isCurrentActive =
          (loggedInEmail.isNotEmpty && regEmail == loggedInEmail);

      final avatar = (savedAvatar != null && savedAvatar.isNotEmpty)
          ? savedAvatar
          : ((isCurrentActive &&
                    userProfile != null &&
                    userProfile.avatarUrl != null &&
                    userProfile.avatarUrl!.isNotEmpty)
                ? userProfile.avatarUrl
                : null);

      final phone = cachedSettings['phoneNumber']?.toString() ??
          cachedSettings['phone']?.toString() ??
          (isCurrentActive ? userProfile?.phone : null);
      final recovery = cachedSettings['recoveryEmail']?.toString() ??
          (isCurrentActive ? userProfile?.recoveryEmail : null);
      final dobStr = cachedSettings['dob']?.toString();
      final dob = dobStr != null ? DateTime.tryParse(dobStr) : null;

      mergedList.add(
        AccountModel(
          id: regEmail,
          name:
              (isCurrentActive &&
                  userProfile != null &&
                  userProfile.name.isNotEmpty)
              ? userProfile.name
              : regName,
          email: regEmail,
          avatarColor: const Color(0xFF195BAC),
          isActive:
              isCurrentActive || (mergedList.isEmpty && loggedInEmail.isEmpty),
          avatarUrl: avatar,
          phone: phone,
          recoveryEmail: recovery,
          dob: dob,
        ),
      );
    }

    // 2. Fetch backend mailboxes if available and merge
    try {
      final list = await UserRepository.getMailboxes();
      if (list.isNotEmpty) {
        for (final acc in list) {
          final accEmail = acc.email.trim().toLowerCase();
          if (accEmail.isNotEmpty &&
              !mergedList.any(
                (a) => a.email.trim().toLowerCase() == accEmail,
              )) {
            final savedAvatar = await TokenService.getUserAvatar(accEmail);
            final cachedSettings = await TokenService.getUserSettings(accEmail) ?? {};
            final avatar = (savedAvatar != null && savedAvatar.isNotEmpty)
                ? savedAvatar
                : acc.avatarUrl;
            final phone = cachedSettings['phoneNumber']?.toString() ??
                cachedSettings['phone']?.toString() ??
                acc.phone;
            final recovery = cachedSettings['recoveryEmail']?.toString() ??
                acc.recoveryEmail;
            final dobStr = cachedSettings['dob']?.toString();
            final dob = dobStr != null ? DateTime.tryParse(dobStr) : acc.dob;

            mergedList.add(
              acc.copyWith(
                id: accEmail,
                isActive: accEmail == loggedInEmail,
                avatarUrl: avatar,
                phone: phone,
                recoveryEmail: recovery,
                dob: dob,
              ),
            );
          }
        }
      }
    } catch (_) {}

    // 3. Fallback to active loggedInEmail if registry was empty
    if (mergedList.isEmpty && loggedInEmail.isNotEmpty) {
      final name = await TokenService.getUserName() ?? 'User';
      final savedAvatar = await TokenService.getUserAvatar(loggedInEmail);
      final cachedSettings = await TokenService.getUserSettings(loggedInEmail) ?? {};
      final avatar = (savedAvatar != null && savedAvatar.isNotEmpty)
          ? savedAvatar
          : userProfile?.avatarUrl;
      final phone = cachedSettings['phoneNumber']?.toString() ??
          cachedSettings['phone']?.toString() ??
          userProfile?.phone;
      final recovery = cachedSettings['recoveryEmail']?.toString() ??
          userProfile?.recoveryEmail;
      final dobStr = cachedSettings['dob']?.toString();
      final dob = dobStr != null ? DateTime.tryParse(dobStr) : null;

      mergedList.add(
        AccountModel(
          id: loggedInEmail,
          name: (userProfile != null && userProfile.name.isNotEmpty)
              ? userProfile.name
              : name,
          email: loggedInEmail,
          avatarColor: const Color(0xFF195BAC),
          isActive: true,
          avatarUrl: avatar,
          phone: phone,
          recoveryEmail: recovery,
          dob: dob,
        ),
      );
    }

    if (!mounted) return;
    final currentActive = state.firstWhere(
      (a) => a.isActive && a.id != 'loading',
      orElse: () => const AccountModel(
        id: '',
        name: '',
        email: '',
        avatarColor: Color(0xFF195BAC),
      ),
    );

    if (currentActive.email.isNotEmpty &&
        !mergedList.any((a) => a.email.trim().toLowerCase() == currentActive.email.trim().toLowerCase())) {
      mergedList.insert(0, currentActive);
    }

    final effectiveTargetEmail = loggedInEmail.isNotEmpty
        ? loggedInEmail
        : currentActive.email.trim().toLowerCase();

    if (mergedList.isNotEmpty) {
      final activeIndex = effectiveTargetEmail.isNotEmpty
          ? mergedList.indexWhere((a) => a.email.trim().toLowerCase() == effectiveTargetEmail)
          : 0;

      final resolvedIndex = activeIndex >= 0 ? activeIndex : 0;
      mergedList = [
        for (int i = 0; i < mergedList.length; i++)
          mergedList[i].copyWith(isActive: i == resolvedIndex),
      ];

      if (!mounted) return;
      state = mergedList;
    }
  }

  void clear() {
    state = [
      const AccountModel(
        id: 'loading',
        name: 'User',
        email: '',
        avatarColor: Color(0xFF195BAC),
        isActive: true,
      ),
    ];
  }

  String get activeAccountId =>
      state.firstWhere((a) => a.isActive, orElse: () => state.first).id;

  AccountModel get activeAccount =>
      state.firstWhere((a) => a.isActive, orElse: () => state.first);

  Future<void> switchAccount(String id, [WidgetRef? ref]) async {
    final cleanId = id.trim().toLowerCase();
    print('[ACCOUNT SWITCH FAST] Switching active account to: $cleanId');

    // 1. Instantly update tokens locally
    await TokenService.switchActiveAccountSession(cleanId);

    final cached = await TokenService.getUserSettings(cleanId);
    final phone = (cached?['phoneNumber'] ?? cached?['phone'])?.toString();
    final recEmail = cached?['recoveryEmail']?.toString();
    DateTime? dob;
    if (cached?['dob'] != null || cached?['birthday'] != null) {
      dob = DateTime.tryParse((cached!['dob'] ?? cached['birthday']).toString());
    }
    final name = (cached?['fullName'] ?? cached?['name'])?.toString();

    // 2. Update account list state immediately so activeAccount is up to date
    if (!mounted) return;
    state = state.map((acc) {
      final accEmail = acc.email.trim().toLowerCase();
      final accId = acc.id.trim().toLowerCase();
      final isTarget = (accEmail == cleanId || accId == cleanId);
      if (isTarget) {
        return acc.copyWith(
          isActive: true,
          phone: (phone != null && phone.isNotEmpty) ? phone : acc.phone,
          recoveryEmail: (recEmail != null && recEmail.isNotEmpty)
              ? recEmail
              : acc.recoveryEmail,
          dob: dob ?? acc.dob,
          name: (name != null && name.isNotEmpty && (acc.name.isEmpty || acc.name == 'User'))
              ? name
              : acc.name,
        );
      }
      return acc.copyWith(isActive: isTarget);
    }).toList();

    // 3. Invalidate settings so active settings reload for new account
    if (ref != null) {
      ref.invalidate(settingsProvider);
    }

    // 4. Non-blocking background call to update primary mailbox on backend
    UserRepository.setPrimaryMailbox(id).catchError((_) {});
  }

  /// Signs out of a single specific account.
  /// If other accounts exist in the account list, automatically switches to the next account.
  /// If no other account exists, clears state and navigates to the login screen.
  Future<void> signOutSingleAccount({
    required String targetEmail,
    required WidgetRef ref,
    required BuildContext context,
  }) async {
    final cleanTarget = targetEmail.trim().toLowerCase();
    print('[ACCOUNT SIGN OUT] Signing out of single account: $cleanTarget');

    // 1. Identify remaining accounts in state (excluding targetEmail)
    final remainingAccounts = state.where((acc) {
      final accEmail = acc.email.trim().toLowerCase();
      final accId = acc.id.trim().toLowerCase();
      return accEmail != cleanTarget &&
          accId != cleanTarget &&
          acc.id != 'loading';
    }).toList();

    // 2. Perform backend/local logout for the target account
    await AuthRepository.logoutSpecificAccount(cleanTarget);

    if (remainingAccounts.isNotEmpty) {
      // 3A. Another account exists! Update state and switch to the next account automatically
      final nextAccount = remainingAccounts.first;
      print(
        '[ACCOUNT SIGN OUT] Switching automatically to next account: ${nextAccount.email}',
      );

      // Remove target from account state list
      state = remainingAccounts;

      // Switch session tokens to next account
      await switchAccount(nextAccount.id, ref);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Signed out of $cleanTarget. Switched to ${nextAccount.email}',
            ),
            backgroundColor: Colors.orangeAccent,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      // 3B. No other accounts exist! Clear tokens and navigate back
      print(
        '[ACCOUNT SIGN OUT] No remaining accounts. Clearing tokens.',
      );
      ref.read(accountsProvider.notifier).clear();
      await AuthRepository.logout();

      if (context.mounted) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Signed out of $cleanTarget'),
            backgroundColor: Colors.orangeAccent,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void markAccountRead(String id) {
    state = state
        .map((acc) => acc.id == id ? acc.copyWith(unreadCount: 0) : acc)
        .toList();
  }

  Future<void> updateAccountFields(
    String id, {
    String? name,
    String? recoveryEmail,
    String? phone,
    String? accountType,
    String? language,
    String? accessibility,
    String? designation,
    DateTime? dob,
  }) async {
    state = state.map((acc) {
      if (acc.id == id) {
        return acc.copyWith(
          name: name ?? acc.name,
          recoveryEmail: recoveryEmail ?? acc.recoveryEmail,
          phone: phone ?? acc.phone,
          accountType: accountType ?? acc.accountType,
          language: language ?? acc.language,
          accessibility: accessibility ?? acc.accessibility,
          designation: designation ?? acc.designation,
          dob: dob ?? acc.dob,
        );
      }
      return acc;
    }).toList();

    final active = state.firstWhere(
      (a) => a.id == id,
      orElse: () => activeAccount,
    );
    if (name != null && active.email.isNotEmpty) {
      await TokenService.saveUserInfo(email: active.email, name: name);
    }

    try {
      await UserRepository.updateProfile({
        'name': ?name,
        'recoveryEmail': ?recoveryEmail,
        'phone': ?phone,
        'accountType': ?accountType,
        'language': ?language,
        'accessibility': ?accessibility,
        'designation': ?designation,
        if (dob != null) 'dob': dob.toIso8601String(),
        'email': active.email,
      });
    } catch (e) {
      print('[PROFILE SYNC ERROR] Failed to update backend profile: $e');
    }
  }

  Future<void> updateProfile(
    String id, {
    required String name,
    required String designation,
    required String experience,
    DateTime? dob,
  }) async {
    await updateAccountFields(
      id,
      name: name,
      designation: designation,
      dob: dob,
    );
  }

  Future<void> updateAvatar(
    String id,
    String avatarUrl, {
    Uint8List? bytes,
    String? filePath,
    String? filename,
  }) async {
    final cleanId = id.trim().toLowerCase();

    // 1. Instantly display preview for immediate UI feedback
    state = state.map((acc) {
      final accEmail = acc.email.trim().toLowerCase();
      final accId = acc.id.trim().toLowerCase();
      if (accId == cleanId || accEmail == cleanId) {
        return acc.copyWith(avatarUrl: avatarUrl);
      }
      return acc;
    }).toList();

    // Clear Flutter's in-memory image cache so old photos do not linger
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();

    final active = state.firstWhere(
      (a) =>
          a.id.trim().toLowerCase() == cleanId ||
          a.email.trim().toLowerCase() == cleanId,
      orElse: () => activeAccount,
    );
    final targetEmail = active.email.isNotEmpty
        ? active.email
        : (await TokenService.getUserEmail() ?? '');

    try {
      final remoteUrl = await UserRepository.uploadAvatar(
        targetEmail,
        avatarUrl,
        bytes: bytes,
        filePath: filePath,
        filename: filename,
      );
      if (remoteUrl != null && remoteUrl.isNotEmpty) {
        // Clear Flutter image cache again before setting the versioned remote URL
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();

        state = state.map((acc) {
          final accEmail = acc.email.trim().toLowerCase();
          final accId = acc.id.trim().toLowerCase();
          if (accId == cleanId || accEmail == cleanId) {
            return acc.copyWith(avatarUrl: remoteUrl);
          }
          return acc;
        }).toList();
        await TokenService.saveUserAvatar(targetEmail, remoteUrl);
      }
    } catch (e) {
      print('[AVATAR SYNC ERROR] Failed to upload avatar to backend: $e');
    }
  }

  Future<void> removeAvatar(String id) async {
    final cleanId = id.trim().toLowerCase();

    // Evict old images from memory cache
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();

    state = state.map((acc) {
      final accEmail = acc.email.trim().toLowerCase();
      final accId = acc.id.trim().toLowerCase();
      if (accId == cleanId || accEmail == cleanId) {
        return acc.copyWith(avatarUrl: null);
      }
      return acc;
    }).toList();

    final active = state.firstWhere(
      (a) =>
          a.id.trim().toLowerCase() == cleanId ||
          a.email.trim().toLowerCase() == cleanId,
      orElse: () => activeAccount,
    );
    final targetEmail = active.email.isNotEmpty
        ? active.email
        : (await TokenService.getUserEmail() ?? '');

    if (targetEmail.isNotEmpty) {
      await TokenService.saveUserAvatar(targetEmail, '');
    }
    final loggedInEmail = await TokenService.getUserEmail();
    if (loggedInEmail != null && loggedInEmail.isNotEmpty) {
      await TokenService.saveUserAvatar(loggedInEmail, '');
    }

    try {
      await UserRepository.deleteAvatar(targetEmail);
    } catch (e) {
      print('[AVATAR REMOVE ERROR] Failed to remove avatar: $e');
    }
  }
}

final accountsProvider =
    StateNotifierProvider<AccountsNotifier, List<AccountModel>>((ref) {
      return AccountsNotifier();
    });

/// Convenience provider: returns just the active account
final activeAccountProvider = Provider<AccountModel>((ref) {
  final accounts = ref.watch(accountsProvider);
  return accounts.firstWhere((a) => a.isActive, orElse: () => accounts.first);
});
