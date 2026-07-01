import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../widgets/item_detail_section.dart';

/// A single labeled value row inside [CategoryDetailsCard].
class CategoryField {
  const CategoryField({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.leading,
    this.valueWidget,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final Widget? leading;
  final Widget? valueWidget;
}

/// Standardized Material 3 card for category-specific metadata on detail screens.
class CategoryDetailsCard extends StatelessWidget {
  const CategoryDetailsCard({
    super.key,
    required this.fields,
    this.title = 'Category Details',
    this.borderRadius,
    this.elevation,
    this.surfaceTintColor,
    this.animateFields = true,
    this.animationIndexOffset = 0,
    this.wrapSection = true,
  });

  final List<CategoryField> fields;
  final String title;
  final BorderRadius? borderRadius;
  final double? elevation;
  final Color? surfaceTintColor;
  final bool animateFields;
  final int animationIndexOffset;
  final bool wrapSection;

  @override
  Widget build(BuildContext context) {
    if (fields.isEmpty) {
      return const SizedBox.shrink();
    }

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < fields.length; i++)
          _buildField(context, fields[i], i),
      ],
    );

    if (!wrapSection) {
      return content;
    }

    return ItemDetailSection(
      title: title,
      borderRadius: borderRadius,
      elevation: elevation,
      surfaceTintColor: surfaceTintColor,
      child: content,
    );
  }

  Widget _buildField(BuildContext context, CategoryField field, int index) {
    final row = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DetailInformationBlock(
          icon: field.icon,
          leading: field.leading,
          label: field.label,
          value: field.value,
          valueWidget: field.valueWidget,
          valueColor: field.valueColor,
        ),
        if (index < fields.length - 1) const DetailFieldGap(),
      ],
    );

    if (!animateFields) {
      return row;
    }

    return _StaggeredFieldFadeIn(
      index: animationIndexOffset + index,
      child: row,
    );
  }
}

class _StaggeredFieldFadeIn extends StatefulWidget {
  const _StaggeredFieldFadeIn({
    required this.index,
    required this.child,
  });

  static const _delayPerItem = Duration(milliseconds: 50);
  static const _duration = Duration(milliseconds: 300);

  final int index;
  final Widget child;

  @override
  State<_StaggeredFieldFadeIn> createState() => _StaggeredFieldFadeInState();
}

class _StaggeredFieldFadeInState extends State<_StaggeredFieldFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  bool _started = false;

  bool _shouldAnimate(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    if (mediaQuery.disableAnimations) {
      return false;
    }
    return !SchedulerBinding
        .instance.platformDispatcher.accessibilityFeatures.disableAnimations;
  }

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: _StaggeredFieldFadeIn._duration);
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _fade = curved;
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(curved);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) {
      return;
    }
    _started = true;

    if (!_shouldAnimate(context)) {
      _controller.value = 1;
      return;
    }

    final delay = _StaggeredFieldFadeIn._delayPerItem * widget.index;
    Future<void>.delayed(delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldAnimate(context)) {
      return widget.child;
    }

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}
