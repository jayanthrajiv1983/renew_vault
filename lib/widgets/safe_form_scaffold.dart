import 'package:flutter/material.dart';

import '../utils/form_padding.dart';
import 'form_action_bar.dart';

/// Scaffold tuned for long scrollable forms with a fixed bottom action bar.
class SafeFormScaffold extends StatelessWidget {
  const SafeFormScaffold({
    super.key,
    required this.appBar,
    required this.child,
    required this.primaryLabel,
    required this.onPrimary,
    this.onCancel,
    this.cancelLabel = 'Cancel',
    this.primaryEnabled = true,
    this.primaryChild,
  });

  final PreferredSizeWidget appBar;
  final Widget child;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final VoidCallback? onCancel;
  final String cancelLabel;
  final bool primaryEnabled;
  final Widget? primaryChild;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: appBar,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                padding: formBodyPadding(context),
                child: child,
              ),
            ),
          ),
          FormActionBar(
            primaryLabel: primaryLabel,
            onPrimary: onPrimary,
            onCancel: onCancel,
            cancelLabel: cancelLabel,
            primaryEnabled: primaryEnabled,
            primaryChild: primaryChild,
          ),
        ],
      ),
    );
  }
}
