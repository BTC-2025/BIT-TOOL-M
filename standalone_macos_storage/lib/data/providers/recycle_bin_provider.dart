import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/storage_models.dart';
import '../repositories/recycle_bin_repository.dart';

class RecycleBinNotifier extends StateNotifier<List<RecycleBinItemModel>> {
  RecycleBinNotifier()
      : super([
          const RecycleBinItemModel(
            id: 'mock_1',
            name: 'Q3_Financial_Summary.pdf',
            app: 'Cliks Business',
            size: '4.2 MB',
            deletedDate: '2 days ago',
            originalLocation: 'Cliks Business > Reports > 2026',
            fileType: 'PDF',
          ),
          const RecycleBinItemModel(
            id: 'mock_2',
            name: 'Client_Meeting_Notes.docx',
            app: 'Cliks',
            size: '1.1 MB',
            deletedDate: '5 days ago',
            originalLocation: 'Cliks > General Channel',
            fileType: 'DOCX',
          ),
          const RecycleBinItemModel(
            id: 'mock_3',
            name: 'Project_Alpha_Deck.key',
            app: 'Bnx mail',
            size: '18.4 MB',
            deletedDate: '1 week ago',
            originalLocation: 'Bnx mail > Trash',
            fileType: 'KEYNOTE',
          ),
        ]);

  Future<void> restoreItem(String id, String app) async {
    try {
      await RecycleBinRepository.restoreItem(id, app: app);
      state = state.where((item) => item.id != id).toList();
    } catch (_) {
      state = state.where((item) => item.id != id).toList();
    }
  }

  Future<void> permanentlyDeleteItem(String id, String app) async {
    try {
      await RecycleBinRepository.permanentlyDeleteItem(id, app: app);
      state = state.where((item) => item.id != id).toList();
    } catch (_) {
      state = state.where((item) => item.id != id).toList();
    }
  }

  void emptyAll() {
    state = [];
  }
}

final storageRecycleBinProvider =
    StateNotifierProvider<RecycleBinNotifier, List<RecycleBinItemModel>>((ref) {
  return RecycleBinNotifier();
});
