/// Standalone macOS Storage & Quota Management Suite
///
/// Complete, self-contained storage management module for Flutter applications.
library;

// UI Pages & Widgets
export 'pages/macos_storage_page.dart';
export 'widgets/sidebar_storage_card.dart';
export 'widgets/storage_breakdown_dialog.dart';

// Data Models
export 'models/storage_models.dart';
export 'models/storage_quota.dart';
export 'models/vault_file.dart';
export 'models/storage_account_model.dart';

// Repositories & API Services
export 'data/repositories/storage_repository.dart';
export 'data/repositories/vault_repository.dart';
export 'data/repositories/recycle_bin_repository.dart';

// Reactive Providers (Riverpod)
export 'data/providers/storage_provider.dart';
export 'data/providers/vault_provider.dart';
export 'data/providers/storage_account_provider.dart';
export 'data/providers/recycle_bin_provider.dart';

// Core Network & Token Management
export 'core/network/api_client.dart';
export 'core/network/api_exception.dart';
export 'core/network/token_service.dart';
