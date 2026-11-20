import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/token_service.dart';
import '../../models/storage_account_model.dart';

class StorageAccountNotifier extends StateNotifier<StorageAccountModel> {
  StorageAccountNotifier() : super(const StorageAccountModel()) {
    _loadFromTokenService();
  }

  Future<void> _loadFromTokenService() async {
    try {
      final email = await TokenService.getUserEmail();
      final name = await TokenService.getUserName();
      final avatar = await TokenService.getUserAvatar();
      if ((email != null && email.isNotEmpty) || (name != null && name.isNotEmpty)) {
        state = state.copyWith(
          email: email ?? state.email,
          name: name ?? (email?.split('@').first ?? state.name),
          avatarUrl: avatar,
        );
      }
    } catch (_) {}
  }

  void updateAccount({required String email, String? name, String? avatarUrl}) {
    state = state.copyWith(
      email: email,
      name: name ?? email.split('@').first,
      avatarUrl: avatarUrl,
    );
  }
}

final activeAccountProvider =
    StateNotifierProvider<StorageAccountNotifier, StorageAccountModel>((ref) {
  return StorageAccountNotifier();
});
