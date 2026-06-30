enum OnboardingIconStyle {
  shieldCalendar,
  notifications,
  fingerprint,
  cameraOcr,
  rocket,
}

class OnboardingPageContent {
  const OnboardingPageContent({
    required this.title,
    this.subtitle,
    required this.description,
    required this.iconStyle,
  });

  final String title;
  final String? subtitle;
  final String description;
  final OnboardingIconStyle iconStyle;
}

const onboardingPages = <OnboardingPageContent>[
  OnboardingPageContent(
    title: 'Welcome to Renew Vault',
    subtitle: 'Your life, organized.',
    description:
        'Track warranties, insurance, documents, and renewals in one secure place.',
    iconStyle: OnboardingIconStyle.shieldCalendar,
  ),
  OnboardingPageContent(
    title: 'Never Miss a Renewal',
    description:
        'Receive smart reminders before important documents and policies expire.',
    iconStyle: OnboardingIconStyle.notifications,
  ),
  OnboardingPageContent(
    title: 'Secure & Private',
    description:
        'Your data stays encrypted and protected with biometric security.',
    iconStyle: OnboardingIconStyle.fingerprint,
  ),
  OnboardingPageContent(
    title: 'Scan Documents Instantly',
    description:
        'Use intelligent OCR to automatically extract renewal details.',
    iconStyle: OnboardingIconStyle.cameraOcr,
  ),
  OnboardingPageContent(
    title: 'Ready to Get Started?',
    description: 'Start organizing your life today.',
    iconStyle: OnboardingIconStyle.rocket,
  ),
];
