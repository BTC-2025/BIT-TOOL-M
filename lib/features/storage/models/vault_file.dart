import 'storage_quota.dart';

/// Model representing a backed-up file in the Mail Backup & Data Vault
/// from GET /api/vault
class VaultFile {
  final int id;
  final String filename;
  final String contentType;
  final int size;
  final DateTime? createdAt;

  const VaultFile({
    required this.id,
    required this.filename,
    required this.contentType,
    required this.size,
    this.createdAt,
  });

  factory VaultFile.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    final createdRaw = json['createdAt']?.toString();
    if (createdRaw != null && createdRaw.isNotEmpty) {
      try {
        parsedDate = DateTime.parse(createdRaw);
      } catch (_) {}
    }

    return VaultFile(
      id: json['id'] is num ? (json['id'] as num).toInt() : 0,
      filename: json['filename']?.toString() ?? 'untitled_backup',
      contentType: json['contentType']?.toString() ?? 'application/octet-stream',
      size: json['size'] is num ? (json['size'] as num).toInt() : 0,
      createdAt: parsedDate,
    );
  }

  String get sizeFormatted => StorageQuota.formatBytes(size);

  String get createdAtFormatted {
    if (createdAt == null) return 'Unknown date';
    final d = createdAt!.toLocal();
    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final month = monthNames[(d.month - 1).clamp(0, 11)];
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '$month ${d.day}, ${d.year} at $hour:$minute';
  }

  bool get isZip => filename.toLowerCase().endsWith('.zip') || contentType.contains('zip');
  bool get isCsv => filename.toLowerCase().endsWith('.csv') || contentType.contains('csv');
  bool get isPdf => filename.toLowerCase().endsWith('.pdf') || contentType.contains('pdf');
  bool get isMailArchive =>
      filename.toLowerCase().endsWith('.eml') ||
      filename.toLowerCase().endsWith('.mbox') ||
      contentType.contains('message');
}
