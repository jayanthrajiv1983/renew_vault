class BackupHistoryEntry {
  const BackupHistoryEntry({
    required this.id,
    required this.createdAt,
    required this.fileName,
    required this.filePath,
    required this.fileSizeBytes,
    this.destination,
  });

  final String id;
  final DateTime createdAt;
  final String fileName;
  final String filePath;
  final int fileSizeBytes;
  final String? destination;

  BackupHistoryEntry copyWith({
    String? id,
    DateTime? createdAt,
    String? fileName,
    String? filePath,
    int? fileSizeBytes,
    String? destination,
  }) {
    return BackupHistoryEntry(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      destination: destination ?? this.destination,
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
    };
  }

  factory BackupHistoryEntry.fromJson(Map<String, dynamic> json) {
    return BackupHistoryEntry(
      id: json['id']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      fileName: json['fileName']?.toString() ?? '',
      filePath: json['filePath']?.toString() ?? '',
      fileSizeBytes: json['fileSizeBytes'] is int
          ? json['fileSizeBytes'] as int
          : int.tryParse(json['fileSizeBytes']?.toString() ?? '') ?? 0,
      destination: json['destination'] as String?,
    );
  }
}
