import 'package:flutter/material.dart';

import 'item_detail_section.dart';

class CategoryDetailRow extends StatelessWidget {
  const CategoryDetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return DetailInformationBlock(
      icon: icon,
      label: label,
      value: value,
      valueColor: valueColor,
    );
  }
}
