import '../models/milestone.dart';
import 'settings_service.dart';
import 'storage_service.dart';

/// Tracks item-count milestones and returns pending celebrations exactly once.
class MilestoneService {
  MilestoneService._();

  static final MilestoneService instance = MilestoneService._();

  /// Marks milestones already reached (existing users, backup restore). No UI.
  Future<void> syncPassedMilestones(int itemCount) async {
    final completed = SettingsService.instance.getCompletedMilestones();
    var changed = false;

    for (final milestone in Milestone.atOrBelow(itemCount)) {
      if (completed.add(milestone.threshold)) {
        changed = true;
      }
    }

    if (changed) {
      await SettingsService.instance.setCompletedMilestones(completed);
    }
  }

  /// One-time bootstrap at app launch for users who already have items.
  Future<void> bootstrapIfNeeded() async {
    if (SettingsService.instance.getMilestonesBootstrapped()) {
      return;
    }

    await syncPassedMilestones(StorageService.instance.getAll().length);
    await SettingsService.instance.setMilestonesBootstrapped(true);
  }

  /// Returns a newly reached milestone for [itemCount], persisting completion.
  Future<Milestone?> checkAndConsume(int itemCount) async {
    final milestone = Milestone.forCount(itemCount);
    if (milestone == null) {
      return null;
    }

    if (SettingsService.instance.isMilestoneCompleted(milestone.threshold)) {
      return null;
    }

    await SettingsService.instance.markMilestoneCompleted(milestone.threshold);
    return milestone;
  }
}
