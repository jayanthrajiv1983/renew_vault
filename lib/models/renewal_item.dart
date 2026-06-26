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
  });

  final String id;
  final String title;
  final String category;
  final String owner;
  final DateTime renewalDate;
  final String notes;
  final List<int> reminderDays;

  RenewalItem copyWith({
    String? id,
    String? title,
    String? category,
    String? owner,
    DateTime? renewalDate,
    String? notes,
    List<int>? reminderDays,
  }) {
    return RenewalItem(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      owner: owner ?? this.owner,
      renewalDate: renewalDate ?? this.renewalDate,
      notes: notes ?? this.notes,
      reminderDays: reminderDays ?? this.reminderDays,
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
    };
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
    );
  }
}
