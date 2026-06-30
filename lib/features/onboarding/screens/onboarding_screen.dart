import 'package:flutter/material.dart';

import '../../../screens/home_screen.dart';
import '../../../theme/app_spacing.dart';
import '../models/onboarding_page_content.dart';
import '../services/onboarding_service.dart';
import '../widgets/onboarding_page_view_item.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  bool get _isLastPage => _currentPage == onboardingPages.length - 1;

  Future<void> _completeOnboarding() async {
    await OnboardingService.instance.markCompleted();
    if (!mounted) {
      return;
    }
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
    );
  }

  void _goToNextPage() {
    if (_isLastPage) {
      _completeOnboarding();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.fieldLabelGap,
                  right: AppSpacing.fieldLabelGap,
                ),
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: const Text('Skip'),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: onboardingPages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  return OnboardingPageViewItem(
                    content: onboardingPages[index],
                    isActive: index == _currentPage,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.fieldLabelGap,
                AppSpacing.screenPadding,
                AppSpacing.screenPadding,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(onboardingPages.length, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: isActive
                              ? colorScheme.primary
                              : colorScheme.outlineVariant,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: AppSpacing.sectionSpacing),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _goToNextPage,
                      child: Text(_isLastPage ? 'Get Started' : 'Next'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
