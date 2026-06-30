import 'dart:async';

import 'package:flutter/material.dart';

import '../core/services/logging_service.dart';
import '../models/renewal_item.dart';
import '../theme/app_spacing.dart';
import '../utils/haptic_feedback.dart';
import 'storage_service.dart';

const _snackBarDuration = Duration(seconds: 4);

/// Root [ScaffoldMessenger] for delete undo snackbars across navigation.
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class _PendingDelete {
  _PendingDelete({
    required this.item,
    required this.timer,
  });

  final RenewalItem item;
  Timer timer;
}

/// Schedules renewal item deletes with undo via snackbar before permanent removal.
class PendingDeleteController extends ChangeNotifier {
  PendingDeleteController._();

  static final PendingDeleteController instance = PendingDeleteController._();

  final _pending = <String, _PendingDelete>{};
  final _snackBarQueue = <String>[];
  bool _isShowingSnackBar = false;

  bool isPending(String id) => _pending.containsKey(id);

  Future<void> scheduleDelete(
    RenewalItem item, {
    VoidCallback? onUiChanged,
  }) async {
    final snapshot = RenewalItem.fromJson(item.toJson());

    if (_pending.containsKey(item.id)) {
      final existing = _pending.remove(item.id)!;
      existing.timer.cancel();
      _snackBarQueue.remove(item.id);
      await StorageService.instance.permanentlyDeleteStashedItem(existing.item);
    }

    await StorageService.instance.stashDelete(item.id);

    final timer = Timer(_snackBarDuration, () {
      unawaited(_commit(item.id));
    });

    _pending[item.id] = _PendingDelete(item: snapshot, timer: timer);

    onUiChanged?.call();
    notifyListeners();
    _enqueueSnackBar(item.id);
  }

  void _enqueueSnackBar(String id) {
    if (!_pending.containsKey(id)) {
      return;
    }
    _snackBarQueue.add(id);
    _showNextSnackBar();
  }

  void _showNextSnackBar() {
    if (_isShowingSnackBar) {
      return;
    }

    while (_snackBarQueue.isNotEmpty &&
        !_pending.containsKey(_snackBarQueue.first)) {
      _snackBarQueue.removeAt(0);
    }
    if (_snackBarQueue.isEmpty) {
      return;
    }

    final id = _snackBarQueue.removeAt(0);
    if (!_pending.containsKey(id)) {
      _showNextSnackBar();
      return;
    }

    final messenger = rootScaffoldMessengerKey.currentState;
    if (messenger == null) {
      return;
    }

    _isShowingSnackBar = true;
    final controller = messenger.showSnackBar(
      SnackBar(
        content: const Text('Item deleted'),
        duration: _snackBarDuration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.cardBorderRadius,
        ),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () => undo(id),
        ),
      ),
    );

    controller.closed.then((reason) {
      _isShowingSnackBar = false;
      if (reason != SnackBarClosedReason.action) {
        unawaited(_commit(id));
      }
      _showNextSnackBar();
    });
  }

  Future<void> undo(String id) async {
    final pending = _pending.remove(id);
    if (pending == null) {
      return;
    }

    AppHaptics.onUndo();
    pending.timer.cancel();
    _snackBarQueue.remove(id);
    await StorageService.instance.save(pending.item);
    notifyListeners();
  }

  Future<void> _commit(String id) async {
    final pending = _pending.remove(id);
    if (pending == null) {
      return;
    }

    pending.timer.cancel();
    _snackBarQueue.remove(id);
    await StorageService.instance.permanentlyDeleteStashedItem(pending.item);
    LoggingService.instance.logInfo('RENEWALS', 'Item deleted');
    notifyListeners();
  }
}
