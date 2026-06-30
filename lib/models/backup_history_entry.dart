enum BackupStorageType {
  local,
  cloud;

  static BackupStorageType fromJsonValue(String? value) {
    switch (value) {
      case 'cloud':
        return BackupStorageType.cloud;
      case 'local':
        return BackupStorageType.local;
      default:
        return BackupStorageType.local;
    }
  }

  String toJsonValue() => name;
}

class BackupHistoryEntry {
  const BackupHistoryEntry({
    required this.id,
    required this.createdAt,
    required this.fileName,
    required this.filePath,
    required this.fileSizeBytes,
    this.destination,
    this.storageType = BackupStorageType.local,
    this.cloudFileId,
  });

  final String id;
  final DateTime createdAt;
  final String fileName;
  final String filePath;
  final int fileSizeBytes;
  final String? destination;
  final BackupStorageType storageType;
  final String? cloudFileId;

  bool get isCloud => storageType == BackupStorageType.cloud;
  bool get isLocal => storageType == BackupStorageType.local;

  String get displayDestination {
    if (destination != null && destination!.isNotEmpty) {
      return destination!;
    }
    return isCloud ? 'Cloud' : 'This device';
  }

  String get storageTypeLabel => isCloud ? 'Cloud backup' : 'Local backup';

  BackupHistoryEntry copyWith({
    String? id,
    DateTime? createdAt,
    String? fileName,
    String? filePath,
    int? fileSizeBytes,
    String? destination,
    BackupStorageType? storageType,
    String? cloudFileId,
  }) {
    return BackupHistoryEntry(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      destination: destination ?? this.destination,
      storageType: storageType ?? this.storageType,
      cloudFileId: cloudFileId ?? this.cloudFileId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'fileName': fileName,
      'filePath': filePath,
      'fileSizeBytes': fileSizeBytes,
      if (destination != null) 'destination': destination,
      'storageType': storageType.toJsonValue(),
      if (cloudFileId != null) 'cloudFileId': cloudFileId,
    };
  }

  factory BackupHistoryEntry.fromJson(Map<String, dynamic> json) {
    final destination = json['destination'] as String?;
    final explicitType =
        BackupStorageType.fromJsonValue(json['storageType'] as String?);
    final storageType = json.containsKey('storageType')
        ? explicitType
        : (destination != null && destination.isNotEmpty)
            ? BackupStorageType.cloud
            : BackupStorageType.local;

    return BackupHistoryEntry(
      id: json['id']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      fileName: json['fileName']?.toString() ?? '',
      filePath: json['filePath']?.toString() ?? '',
      fileSizeBytes: json['fileSizeBytes'] is int
          ? json['fileSizeBytes'] as int
          : int.tryParse(json['fileSizeBytes']?.toString() ?? '') ?? 0,
      destination: destination,
      storageType: storageType,
      cloudFileId: json['cloudFileId'] as String?,
    );
  }
}
