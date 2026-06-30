import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Local placeholder legal documents bundled with the app.
enum LegalDocument {
  privacyPolicy(
    title: 'Privacy Policy',
    assetPath: 'assets/legal/privacy_policy.html',
  ),
  termsAndConditions(
    title: 'Terms & Conditions',
    assetPath: 'assets/legal/terms_and_conditions.html',
  );

  const LegalDocument({
    required this.title,
    required this.assetPath,
  });

  final String title;
  final String assetPath;
}

/// Displays a bundled HTML legal document in an in-app WebView with theme-aware styling.
class LegalDocumentScreen extends StatefulWidget {
  const LegalDocumentScreen({required this.document, super.key});

  final LegalDocument document;

  @override
  State<LegalDocumentScreen> createState() => _LegalDocumentScreenState();
}

class _LegalDocumentScreenState extends State<LegalDocumentScreen> {
  WebViewController? _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    try {
      final bodyHtml = await rootBundle.loadString(widget.document.assetPath);
      if (!mounted) {
        return;
      }
      final themedHtml = _wrapWithTheme(bodyHtml, Theme.of(context));
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.disabled)
        ..setBackgroundColor(Theme.of(context).colorScheme.surface)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (_) {
              if (mounted) {
                setState(() => _loading = false);
              }
            },
            onWebResourceError: (error) {
              if (mounted) {
                setState(() {
                  _loading = false;
                  _error = error.description;
                });
              }
            },
          ),
        )
        ..loadHtmlString(themedHtml);
      setState(() => _controller = controller);
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = error.toString();
        });
      }
    }
  }

  String _wrapWithTheme(String bodyHtml, ThemeData theme) {
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final background = _colorToHex(scheme.surface);
    final textColor = _colorToHex(scheme.onSurface);
    final mutedColor = _colorToHex(scheme.onSurfaceVariant);
    final linkColor = _colorToHex(scheme.primary);
    final headingColor = _colorToHex(scheme.onSurface);
    final fontFamily = textTheme.bodyMedium?.fontFamily ?? 'sans-serif';

    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    :root {
      color-scheme: ${theme.brightness == Brightness.dark ? 'dark' : 'light'};
    }
    body {
      margin: 0;
      padding: 16px 20px 32px;
      background-color: $background;
      color: $textColor;
      font-family: $fontFamily, system-ui, -apple-system, sans-serif;
      font-size: 16px;
      line-height: 1.55;
      -webkit-text-size-adjust: 100%;
    }
    h1 {
      color: $headingColor;
      font-size: 1.5rem;
      font-weight: 600;
      margin: 0 0 0.75rem;
      line-height: 1.3;
    }
    h2 {
      color: $headingColor;
      font-size: 1.125rem;
      font-weight: 600;
      margin: 1.5rem 0 0.5rem;
      line-height: 1.35;
    }
    p {
      margin: 0 0 0.875rem;
    }
    ul {
      margin: 0 0 0.875rem;
      padding-left: 1.25rem;
    }
    li {
      margin-bottom: 0.375rem;
    }
    em {
      color: $mutedColor;
    }
    a {
      color: $linkColor;
      text-decoration: underline;
    }
    strong {
      font-weight: 600;
    }
  </style>
</head>
<body>
$bodyHtml
</body>
</html>
''';
  }

  String _colorToHex(Color color) {
    final value = color.toARGB32();
    final r = (value >> 16) & 0xFF;
    final g = (value >> 8) & 0xFF;
    final b = value & 0xFF;
    return '#${r.toRadixString(16).padLeft(2, '0')}'
        '${g.toRadixString(16).padLeft(2, '0')}'
        '${b.toRadixString(16).padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.document.title),
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Could not load document',
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : Stack(
              children: [
                if (_controller != null)
                  WebViewWidget(controller: _controller!),
                if (_loading)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
    );
  }
}
