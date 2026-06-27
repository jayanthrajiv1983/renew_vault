import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../models/family_member.dart';
import 'hive_encryption_service.dart';

class FamilyService {
  FamilyService._();

  static final FamilyService instance = FamilyService._();

  static const _boxName = 'family_members';

  Box? _box;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) {
      return;
    }

    debugPrint('FamilyService: initializing');
    try {
      _box = await HiveEncryptionService.instance.openBox(_boxName);
      debugPrint('FamilyService: box opened');
      _initialized = true;
      await ensureDefaultSelf();
      debugPrint('FamilyService: init complete');
    } catch (error, stackTrace) {
      debugPrint('FamilyService: init failed: $error');
      debugPrint('$stackTrace');
      rethrow;
    }
  }

  List<FamilyMember> getAll() {
    final box = _box;
    if (box == null || box.isEmpty) {
      return [];
    }

    final members = box.values
        .map(
          (value) => FamilyMember.fromJson(
            Map<String, dynamic>.from(value as Map),
          ),
        )
        .toList();

    members.sort((a, b) => a.name.compareTo(b.name));
    return members;
  }

  FamilyMember? getById(String id) {
    final value = _box?.get(id);
    if (value == null) {
      return null;
    }
    return FamilyMember.fromJson(Map<String, dynamic>.from(value as Map));
  }

  FamilyMember? getByName(String name) {
    for (final member in getAll()) {
      if (member.name == name) {
        return member;
      }
    }
    return null;
  }

  Future<void> save(FamilyMember member) async {
    final box = _box;
    if (box == null || !box.isOpen) {
      throw StateError(
        'FamilyService has not been initialized. Call init() first.',
      );
    }

    await _putMember(box, member);
  }

  Future<void> delete(String id) async {
    await _box!.delete(id);
  }

  Future<void> replaceAll(List<FamilyMember> members) async {
    await _box!.clear();
    for (final member in members) {
      await _putMember(_box!, member);
    }
    await ensureDefaultSelf();
  }

  Future<void> ensureDefaultSelf() async {
    final box = _box;
    if (box == null || !box.isOpen || box.isNotEmpty) {
      return;
    }

    await _putMember(
      box,
      const FamilyMember(
        id: 'self',
        name: 'Self',
        relationship: 'Self',
      ),
    );
  }

  Future<void> _putMember(Box box, FamilyMember member) async {
    final data = Map<String, dynamic>.from(member.toJson())
      ..removeWhere((_, value) => value == null);
    await box.put(member.id, data);
  }
}
