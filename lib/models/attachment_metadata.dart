enum AttachmentFileType {
  jpg,
  png,
  pdf;

  String get label => switch (this) {
        AttachmentFileType.jpg => 'JPG',
        AttachmentFileType.png => 'PNG',
        AttachmentFileType.pdf => 'PDF',
      };

  String get extension => switch (this) {
        AttachmentFileType.jpg => 'jpg',
        AttachmentFileType.png => 'png',
        AttachmentFileType.pdf => 'pdf',
      };

  static AttachmentFileType? fromExtension(String extension) {
    switch (extension.toLowerCase().replaceAll('.', '')) {
      case 'jpg':
      case 'jpeg':
        return AttachmentFileType.jpg;
      case 'png':
        return AttachmentFileType.png;
      case 'pdf':
        return AttachmentFileType.pdf;
      default:
        return null;
    }
  }

  static AttachmentFileType fromJson(String value) {
    return AttachmentFileType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => AttachmentFileType.jpg,
    );
  }
}

class AttachmentMetadata {
  const AttachmentMetadata({
    required this.id,
    required this.renewalItemId,
    required this.fileName,
    required this.fileType,
    required this.localPath,
    required this.uploadedAt,
    this.fileSize,
  });

  final String id;
  final String renewalItemId;
  final String fileName;
  final AttachmentFileType fileType;
  final String localPath;
  final DateTime uploadedAt;
  final int? fileSize;

  AttachmentMetadata copyWith({
    String? id,
    String? renewalItemId,
    String? fileName,
    AttachmentFileType? fileType,
    String? localPath,
    DateTime? uploadedAt,
    int? fileSize,
  }) {
    return AttachmentMetadata(
      id: id ?? this.id,
      renewalItemId: renewalItemId ?? this.renewalItemId,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      localPath: localPath ?? this.localPath,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      fileSize: fileSize ?? this.fileSize,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'renewalItemId': renewalItemId,
      'fileName': fileName,
      'fileType': fileType.name,
      'localPath': localPath,
      'uploadedAt': uploadedAt.toIso8601String(),
      if (fileSize != null) 'fileSize': fileSize,
    };
  }

  factory AttachmentMetadata.fromJson(Map<String, dynamic> json) {
    return AttachmentMetadata(
      id: json['id'] as String,
      renewalItemId: json['renewalItemId'] as String,
      fileName: json['fileName'] as String,
      fileType: AttachmentFileType.fromJson(json['fileType'] as String? ?? 'jpg'),
      localPath: json['localPath'] as String,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
      fileSize: (json['fileSize'] as num?)?.toInt(),
    );
  }
}
