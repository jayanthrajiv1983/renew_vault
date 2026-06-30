import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../services/diagnostics_report_service.dart';
import '../../../theme/app_spacing.dart';
import '../../../utils/form_padding.dart';
import '../../../utils/format_helpers.dart';

class AppDiagnosticsScreen extends StatefulWidget {
  const AppDiagnosticsScreen({super.key});

  @override
  State<AppDiagnosticsScreen> createState() => _AppDiagnosticsScreenState();
}

class _AppDiagnosticsScreenState extends State<AppDiagnosticsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryController;
  late final List<Animation<double>> _sectionFades;

  DiagnosticsReportData? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _sectionFades = List.generate(
      4,
      (index) => CurvedAnimation(
        parent: _entryController,
        curve: Interval(
          index * 0.08,
          0.55 + index * 0.12,
          curve: Curves.easeOut,
        ),
      ),
    );
    _loadDiagnostics();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  Future<void> _loadDiagnostics() async {
    try {
      final data = await DiagnosticsReportService.instance.collect();
      if (!mounted) {
        return;
      }
      setState(() {
        _data = data;
        _loading = false;
      });
      _entryController.forward();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  String? _getDiagnosticsReportText() {
    final data = _data;
    if (data == null) {
      return null;
    }
    return DiagnosticsReportService.instance.buildReportText(data);
  }

  Future<void> _copyDiagnostics() async {
    final report = _getDiagnosticsReportText();
    if (report == null) {
      return;
    }

    await Clipboard.setData(ClipboardData(text: report));

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Diagnostics copied to clipboard.'),
      ),
    );
  }

  Future<void> _shareDiagnostics() async {
    final report = _getDiagnosticsReportText();
    if (report == null) {
      return;
    }

    await SharePlus.instance.share(ShareParams(text: report));
  }

  String _yesNo(bool value) => value ? 'Yes' : 'No';

  Widget _diagnosticTile({
    required String title,
    String? subtitle,
    String? value,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: value != null
          ? Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          : null,
    );
  }

  Widget _sectionCard({
    required Animation<double> fade,
    required String title,
    required List<Widget> children,
  }) {
    return FadeTransition(
      opacity: fade,
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.cardPadding,
                AppSpacing.cardPadding,
                AppSpacing.cardPadding,
                AppSpacing.fieldLabelGap,
              ),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _divider() => const Divider(height: 1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Diagnostics'),
        actions: [
          if (!_loading && _error == null) ...[
            IconButton(
              icon: const Icon(Icons.share_rounded),
              tooltip: 'Share',
              onPressed: _shareDiagnostics,
            ),
            IconButton(
              icon: const Icon(Icons.copy_rounded),
              tooltip: 'Copy',
              onPressed: _copyDiagnostics,
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: listScrollPadding(context),
                      child: Text(
                        'Could not load diagnostics.\n$_error',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final data = _data!;

    return ListView(
      padding: listScrollPadding(context),
      children: [
        _sectionCard(
          fade: _sectionFades[0],
          title: 'App Information',
          children: [
            _diagnosticTile(
              title: 'Version',
              value: data.appVersion,
            ),
            _divider(),
            _diagnosticTile(
              title: 'Build Number',
              value: data.buildNumber,
            ),
            _divider(),
            _diagnosticTile(
              title: 'Release Channel',
              value: data.releaseChannel,
            ),
            _divider(),
            _diagnosticTile(
              title: 'Package Name',
              value: data.packageName,
            ),
            _divider(),
            _diagnosticTile(
              title: 'Build Mode',
              value: data.buildMode,
            ),
          ],
        ),
        AppSpacing.gapSection,
        _sectionCard(
          fade: _sectionFades[1],
          title: 'Device Information',
          children: [
            _diagnosticTile(
              title: 'Platform',
              value: data.platform,
            ),
            _divider(),
            _diagnosticTile(
              title: 'OS Version',
              value: data.osVersion,
            ),
            _divider(),
            _diagnosticTile(
              title: 'Device Manufacturer',
              value: data.manufacturer,
            ),
            _divider(),
            _diagnosticTile(
              title: 'Device Model',
              value: data.deviceModel,
            ),
          ],
        ),
        AppSpacing.gapSection,
        _sectionCard(
          fade: _sectionFades[2],
          title: 'Application Information',
          children: [
            _diagnosticTile(
              title: 'Dark Mode Enabled',
              value: _yesNo(data.darkModeEnabled),
            ),
            _divider(),
            _diagnosticTile(
              title: 'App Lock Enabled',
              value: _yesNo(data.appLockEnabled),
            ),
            _divider(),
            _diagnosticTile(
              title: 'Notifications Enabled',
              value: _yesNo(data.notificationsEnabled),
            ),
            _divider(),
            _diagnosticTile(
              title: 'Last Backup Date',
              value: data.lastBackupDate,
            ),
            _divider(),
            _diagnosticTile(
              title: 'Total Renewals',
              value: '${data.totalRenewals}',
            ),
            _divider(),
            _diagnosticTile(
              title: 'Total Family Members',
              value: '${data.totalFamilyMembers}',
            ),
            _divider(),
            _diagnosticTile(
              title: 'Total Attachments',
              value: '${data.totalAttachments}',
            ),
          ],
        ),
        AppSpacing.gapSection,
        _sectionCard(
          fade: _sectionFades[3],
          title: 'Storage Information',
          children: [
            _diagnosticTile(
              title: 'Database Size',
              value: formatFileSize(data.databaseSizeBytes),
            ),
            _divider(),
            _diagnosticTile(
              title: 'Attachments Size',
              value: formatFileSize(data.attachmentsSizeBytes),
            ),
            _divider(),
            _diagnosticTile(
              title: 'Total App Storage Used',
              value: formatFileSize(data.totalStorageBytes),
            ),
          ],
        ),
      ],
    );
  }
}
