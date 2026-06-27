import 'package:archive/archive.dart';

/// Parsed backup contents ready for user confirmation before restore.
class BackupPreview {
  const BackupPreview({
    required this.data,
    required this.renewalCount,
    required this.familyMemberCount,
    required this.attachmentCount,
    this.archive,
  });

  final Map<String, dynamic> data;
  final int renewalCount;
  final int familyMemberCount;
  final int attachmentCount;

  /// Non-null for encrypted `.rvbackup` files; holds attachment payloads until restore.
  final Archive? archive;
}
