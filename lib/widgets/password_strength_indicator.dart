import 'package:flutter/material.dart';
import '../services/password_generator_service.dart';

/// A visual password strength indicator widget
class PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  final bool showFeedback;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
    this.showFeedback = true,
  });

  @override
  Widget build(BuildContext context) {
    final result = PasswordGeneratorService.calculateStrength(password);
    final colors = Theme.of(context).colorScheme;

    // Determine color based on strength
    Color strengthColor;
    switch (result.strength) {
      case PasswordStrength.veryWeak:
        strengthColor = Colors.red;
        break;
      case PasswordStrength.weak:
        strengthColor = Colors.orange;
        break;
      case PasswordStrength.fair:
        strengthColor = Colors.yellow.shade700;
        break;
      case PasswordStrength.strong:
        strengthColor = Colors.lightGreen;
        break;
      case PasswordStrength.veryStrong:
        strengthColor = Colors.green;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Strength bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: result.score,
            backgroundColor: colors.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
            minHeight: 8,
          ),
        ),
        if (showFeedback && password.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            result.feedback,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: strengthColor,
                ),
          ),
        ],
      ],
    );
  }
}
