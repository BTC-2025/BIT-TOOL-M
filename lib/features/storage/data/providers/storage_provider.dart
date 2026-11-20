import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/storage_quota.dart';
import '../repositories/storage_repository.dart';
import 'storage_account_provider.dart';

class StorageQuotaNotifier extends StateNotifier<AsyncValue<StorageQuota>> {
  static StorageQuotaNotifier? instance;
  bool _isFetching = false;
  String? _currentEmail;

  StorageQuotaNotifier([String? initialEmail]) : super(const AsyncValue.loading()) {
    instance = this;
    _currentEmail = initialEmail;
    StorageDebug.log('[STORAGE NOTIFIER] Initialized in constructor for ${_currentEmail ?? "default"}');
    fetchQuota(_currentEmail);
  }

  @override
  void dispose() {
    StorageDebug.log('[STORAGE NOTIFIER] DISPOSE CALLED, mounted=$mounted');
    if (instance == this) instance = null;
    super.dispose();
  }

  Future<void> fetchQuota([String? email]) async {
    if (!mounted) return;
    if (email != null && email.isNotEmpty) {
      _currentEmail = email;
    }
    if (_isFetching) {
      StorageDebug.log('[STORAGE] Duplicate request prevented');
      return;
    }
    _isFetching = true;
    if (state.hasValue && state.valueOrNull != null) {
      state = const AsyncLoading<StorageQuota>().copyWithPrevious(state);
    } else {
      state = const AsyncValue.loading();
    }
    try {
      final quota = await StorageRepository.fetchStorageQuota(_currentEmail);
      if (mounted) {
        state = AsyncValue.data(quota);
      }
    } catch (e, st) {
      if (mounted) {
        state = AsyncValue.error(e, st);
      }
    } finally {
      _isFetching = false;
    }
  }

  Future<void> refresh() async {
    if (!mounted) return;
    _isFetching = false;
    StorageRepository.resetInFlight();
    await fetchQuota(_currentEmail);
  }

  Future<void> onAccountSwitched(String nextEmail) async {
    if (!mounted) return;
    StorageDebug.log('[STORAGE] Account switch detected to $nextEmail, resetting quota');
    _currentEmail = nextEmail;
    state = const AsyncValue.loading();
    _isFetching = false;
    StorageRepository.resetInFlight();
    await fetchQuota(nextEmail);
  }
}

final storageQuotaProvider =
    StateNotifierProvider<StorageQuotaNotifier, AsyncValue<StorageQuota>>((ref) {
  final activeEmail = ref.watch(activeAccountProvider.select((a) => a.email));
  final notifier = StorageQuotaNotifier(activeEmail.isNotEmpty ? activeEmail : null);

  ref.listen<String>(
    activeAccountProvider.select((a) => a.email),
    (previous, next) {
      if (previous != next && next.isNotEmpty && notifier.mounted) {
        notifier.onAccountSwitched(next);
      }
    },
  );

  return notifier;
});
