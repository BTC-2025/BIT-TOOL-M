import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/vault_file.dart';
import '../repositories/vault_repository.dart';

class VaultFilesNotifier extends StateNotifier<AsyncValue<List<VaultFile>>> {
  VaultFilesNotifier() : super(const AsyncValue.loading()) {
    loadFiles();
  }

  Future<void> loadFiles() async {
    try {
      final files = await VaultRepository.listVaultFiles();
      state = AsyncValue.data(files);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await loadFiles();
  }

  Future<void> deleteFile(int id) async {
    final prev = state.valueOrNull ?? [];
    try {
      await VaultRepository.deleteVaultFile(id);
      state = AsyncValue.data(prev.where((f) => f.id != id).toList());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> uploadFile(String path) async {
    try {
      final newFile = await VaultRepository.uploadVaultFile(path);
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data([newFile, ...current]);
    } catch (e) {
      rethrow;
    }
  }
}

final vaultFilesProvider =
    StateNotifierProvider<VaultFilesNotifier, AsyncValue<List<VaultFile>>>((ref) {
  return VaultFilesNotifier();
});
