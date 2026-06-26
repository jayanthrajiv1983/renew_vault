class OcrCorrection {
  const OcrCorrection({
    required this.fieldName,
    required this.originalValue,
    required this.correctedValue,
    this.documentType,
    this.usageCount = 1,
    this.updatedAt,
  });

  final String fieldName;
  final String originalValue;
  final String correctedValue;
  final String? documentType;
  final int usageCount;
  final DateTime? updatedAt;

  OcrCorrection copyWith({
    String? fieldName,
    String? originalValue,
    String? correctedValue,
    String? documentType,
    int? usageCount,
    DateTime? updatedAt,
  }) {
    return OcrCorrection(
      fieldName: fieldName ?? this.fieldName,
      originalValue: originalValue ?? this.originalValue,
      correctedValue: correctedValue ?? this.correctedValue,
      documentType: documentType ?? this.documentType,
      usageCount: usageCount ?? this.usageCount,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fieldName': fieldName,
      'originalValue': originalValue,
      'correctedValue': correctedValue,
      if (documentType != null) 'documentType': documentType,
      'usageCount': usageCount,
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  factory OcrCorrection.fromJson(Map<String, dynamic> json) {
    return OcrCorrection(
      fieldName: json['fieldName']?.toString() ?? '',
      originalValue: json['originalValue']?.toString() ?? '',
      correctedValue: json['correctedValue']?.toString() ?? '',
      documentType: json['documentType'] as String?,
      usageCount: json['usageCount'] is int
          ? json['usageCount'] as int
          : int.tryParse(json['usageCount']?.toString() ?? '') ?? 1,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }
}
