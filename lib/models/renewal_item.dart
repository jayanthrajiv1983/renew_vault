import 'attachment_metadata.dart';

class RenewalItem {
  static const defaultReminderDays = [30, 7, 1];

  const RenewalItem({
    required this.id,
    required this.title,
    required this.category,
    required this.owner,
    required this.renewalDate,
    this.notes = '',
    this.reminderDays = defaultReminderDays,
    this.notificationIds = const {},
    this.metadata = const {},
    this.attachments = const [],
  });

  final String id;
  final String title;
  final String category;
  final String owner;
  final DateTime renewalDate;
  final String notes;
  final List<int> reminderDays;
  final Map<String, int> notificationIds;
  final Map<String, dynamic> metadata;
  final List<AttachmentMetadata> attachments;

  RenewalItem copyWith({
    String? id,
    String? title,
    String? category,
    String? owner,
    DateTime? renewalDate,
    String? notes,
    List<int>? reminderDays,
    Map<String, int>? notificationIds,
    Map<String, dynamic>? metadata,
    List<AttachmentMetadata>? attachments,
  }) {
    return RenewalItem(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      owner: owner ?? this.owner,
      renewalDate: renewalDate ?? this.renewalDate,
      notes: notes ?? this.notes,
      reminderDays: reminderDays ?? this.reminderDays,
      notificationIds: notificationIds ?? this.notificationIds,
      metadata: metadata ?? this.metadata,
      attachments: attachments ?? this.attachments,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'owner': owner,
      'renewalDate': renewalDate.toIso8601String(),
      'notes': notes,
      'reminderDays': reminderDays,
      'notificationIds': notificationIds,
      'metadata': metadata,
      'attachments': attachments.map((attachment) => attachment.toJson()).toList(),
    };
  }

  static List<AttachmentMetadata> _parseAttachments(dynamic raw) {
    if (raw is! List) {
      return [];
    }
    return raw
        .whereType<Map>()
        .map(
          (entry) => AttachmentMetadata.fromJson(
            Map<String, dynamic>.from(entry),
          ),
        )
        .toList();
  }

  static Map<String, int> _parseNotificationIds(dynamic raw) {
    if (raw is Map) {
      return raw.map(
        (key, value) => MapEntry(key.toString(), (value as num).toInt()),
      );
    }
    return {};
  }

  static Map<String, dynamic> _parseMetadata(Map<String, dynamic> json) {
    final raw = json['metadata'] ?? json['categoryDetails'];
    if (raw is Map) {
      final metadata = Map<String, dynamic>.from(raw);
      if (metadata.containsKey('issuingAuthority') &&
          !metadata.containsKey('authority')) {
        metadata['authority'] = metadata.remove('issuingAuthority');
      }
      return metadata;
    }
    return {};
  }

  factory RenewalItem.fromJson(Map<String, dynamic> json) {
    return RenewalItem(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      owner: json['owner'] as String,
      renewalDate: DateTime.parse(json['renewalDate'] as String),
      notes: json['notes'] as String? ?? '',
      reminderDays: (json['reminderDays'] as List<dynamic>?)
              ?.map((day) => day as int)
              .toList() ??
          defaultReminderDays,
      notificationIds: _parseNotificationIds(json['notificationIds']),
      metadata: _parseMetadata(json),
      attachments: _parseAttachments(json['attachments']),
    );
  }
}
