/// Item-count milestone shown once when the user organically adds renewals.
class Milestone {
  const Milestone({
    required this.threshold,
    required this.message,
  });

  final int threshold;
  final String message;

  static const milestones = <Milestone>[
    Milestone(threshold: 1, message: '🎉 Great start!'),
    Milestone(threshold: 10, message: '🎉 You\'re getting organized!'),
    Milestone(threshold: 25, message: '🎉 Building momentum!'),
    Milestone(threshold: 50, message: '🎉 Life fully organized!'),
    Milestone(threshold: 100, message: '🎉 Master organizer!'),
  ];

  static Milestone? forCount(int count) {
    for (final milestone in milestones) {
      if (milestone.threshold == count) {
        return milestone;
      }
    }
    return null;
  }

  static Iterable<Milestone> atOrBelow(int count) =>
      milestones.where((milestone) => milestone.threshold <= count);
}
