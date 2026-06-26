import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../utils/metadata_utils.dart';
import 'category_detail_row.dart';

class MetadataDisplay extends StatelessWidget {
  const MetadataDisplay({
    super.key,
    required this.category,
    required this.metadata,
  });

  final String category;
  final Map<String, dynamic> metadata;

  @override
  Widget build(BuildContext context) {
    final sections = metadataSectionsForCategory(category, metadata);
    if (sections.isEmpty) {
      return Text(
        'No additional details',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      );
    }

    if (sections.length == 1) {
      return _MetadataSectionContent(entries: sections.first.entries);
    }

    return _MetadataExpansionSections(sections: sections);
  }
}

class _MetadataExpansionSections extends StatelessWidget {
  const _MetadataExpansionSections({required this.sections});

  final List<PopulatedMetadataSection> sections;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sectionShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
    );

    return Theme(
      data: theme.copyWith(
        dividerColor: Colors.transparent,
        expansionTileTheme: ExpansionTileThemeData(
          backgroundColor: colorScheme.surfaceContainerLow,
          collapsedBackgroundColor: colorScheme.surfaceContainerLow,
          iconColor: colorScheme.onSurfaceVariant,
          collapsedIconColor: colorScheme.onSurfaceVariant,
          textColor: colorScheme.onSurface,
          collapsedTextColor: colorScheme.onSurface,
          shape: sectionShape,
          collapsedShape: sectionShape,
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.cardSpacing,
            vertical: AppSpacing.fieldLabelGap,
          ),
          expandedAlignment: Alignment.centerLeft,
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.cardSpacing,
            0,
            AppSpacing.cardSpacing,
            AppSpacing.cardSpacing,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < sections.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.fieldLabelGap),
            ExpansionTile(
              initiallyExpanded: true,
              title: Text(
                sections[i].title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              children: [
                _MetadataSectionContent(entries: sections[i].entries),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MetadataSectionContent extends StatelessWidget {
  const _MetadataSectionContent({required this.entries});

  final List<MapEntry<String, dynamic>> entries;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          if (i > 0)
            Divider(
              height: 1,
              color: Theme.of(context).colorScheme.outlineVariant.withValues(
                    alpha: 0.5,
                  ),
            ),
          CategoryDetailRow(
            icon: metadataIcon(entries[i].key),
            label: metadataLabel(entries[i].key),
            value: formatMetadataValue(entries[i].key, entries[i].value),
          ),
        ],
      ],
    );
  }
}
