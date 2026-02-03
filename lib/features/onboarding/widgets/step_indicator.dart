import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Animated step indicator for onboarding
class StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const StepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (index) {
        final isActive = index <= currentStep;
        final isCurrent = index == currentStep;

        return Row(
          children: [
            // Step dot
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isCurrent ? 32 : 12,
              height: 12,
              decoration: BoxDecoration(
                gradient: isActive ? AppColors.analyticsGradient : null,
                color: isActive ? null : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(6),
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: AppColors.primaryNeon.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
            ),
            // Connector line
            if (index < totalSteps - 1)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 24,
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: index < currentStep
                      ? AppColors.primaryNeon
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
          ],
        );
      }),
    );
  }
}
