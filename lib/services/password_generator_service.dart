import 'dart:math';

/// Password strength levels
enum PasswordStrength {
  veryWeak,
  weak,
  fair,
  strong,
  veryStrong,
}

/// Configuration for password generation
class PasswordConfig {
  final int length;
  final bool uppercase;
  final bool lowercase;
  final bool numbers;
  final bool symbols;
  final bool excludeAmbiguous;

  const PasswordConfig({
    this.length = 16,
    this.uppercase = true,
    this.lowercase = true,
    this.numbers = true,
    this.symbols = true,
    this.excludeAmbiguous = false,
  });
}

/// Result of password strength calculation
class PasswordStrengthResult {
  final PasswordStrength strength;
  final double score; // 0.0 to 1.0
  final String feedback;

  const PasswordStrengthResult({
    required this.strength,
    required this.score,
    required this.feedback,
  });
}

/// Service for generating and evaluating passwords
class PasswordGeneratorService {
  static const String _uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _lowercase = 'abcdefghijklmnopqrstuvwxyz';
  static const String _numbers = '0123456789';
  static const String _symbols = '!@#\$%^&*()_+-=[]{}|;:,.<>?';
  static const String _ambiguous = 'il1Lo0O';

  static final  _random = Random.secure();

  /// Generate a random password based on configuration
  static String generatePassword(PasswordConfig config) {
    if (config.length < 4) {
      throw ArgumentError('Password length must be at least 4');
    }

    if (!config.uppercase &&
        !config.lowercase &&
        !config.numbers &&
        !config.symbols) {
      throw ArgumentError('At least one character type must be selected');
    }

    // Build character pool
    String pool = '';
    if (config.uppercase) pool += _uppercase;
    if (config.lowercase) pool += _lowercase;
    if (config.numbers) pool += _numbers;
    if (config.symbols) pool += _symbols;

    // Remove ambiguous characters if requested
    if (config.excludeAmbiguous) {
      pool = pool.split('').where((c) => !_ambiguous.contains(c)).join();
    }

    // Generate password ensuring at least one character from each enabled type
    final password = StringBuffer();
    final usedTypes = <String>[];

    // Add at least one from each enabled type
    if (config.uppercase) {
      usedTypes.add(_uppercase);
    }
    if (config.lowercase) {
      usedTypes.add(_lowercase);
    }
    if (config.numbers) {
      usedTypes.add(_numbers);
    }
    if (config.symbols) {
      usedTypes.add(_symbols);
    }

    // Add one from each type
    for (final type in usedTypes) {
      String filtered = type;
      if (config.excludeAmbiguous) {
        filtered = filtered.split('').where((c) => !_ambiguous.contains(c)).join();
      }
      password.write(filtered[_random.nextInt(filtered.length)]);
    }

    // Fill the rest randomly
    while (password.length < config.length) {
      password.write(pool[_random.nextInt(pool.length)]);
    }

    // Shuffle the password
    final chars = password.toString().split('');
    chars.shuffle(_random);
    return chars.join();
  }

  /// Generate a passphrase (more memorable)
  static String generatePassphrase({int wordCount = 4, String separator = '-'}) {
    // Common word list (in production, use a larger dictionary)
    const words = [
      'anchor', 'breeze', 'castle', 'dolphin', 'eclipse', 'forest', 'garden',
      'horizon', 'island', 'jungle', 'knight', 'lantern', 'mountain', 'nebula',
      'ocean', 'phoenix', 'quartz', 'rainbow', 'summit', 'thunder', 'universe',
      'valley', 'whisper', 'crystal', 'meadow', 'aurora', 'cascade', 'ember',
      'glacier', 'harmony', 'cosmos', 'tempest', 'zenith', 'prism', 'beacon',
    ];

    final selected = <String>[];
    for (int i = 0; i < wordCount; i++) {
      selected.add(words[_random.nextInt(words.length)]);
    }

    return selected.join(separator);
  }

  /// Calculate password strength
  static PasswordStrengthResult calculateStrength(String password) {
    if (password.isEmpty) {
      return const PasswordStrengthResult(
        strength: PasswordStrength.veryWeak,
        score: 0.0,
        feedback: 'Password is empty',
      );
    }

    double score = 0.0;
    String feedback = '';

    // Length score (max 0.3)
    if (password.length >= 16) {
      score += 0.3;
    } else if (password.length >= 12) {
      score += 0.2;
    } else if (password.length >= 8) {
      score += 0.1;
    } else {
      feedback = 'Password is too short (minimum 12 recommended)';
    }

    // Character variety score (max 0.4)
    bool hasUpper = password.contains(RegExp(r'[A-Z]'));
    bool hasLower = password.contains(RegExp(r'[a-z]'));
    bool hasDigit = password.contains(RegExp(r'[0-9]'));
    bool hasSymbol = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    int varietyCount = 0;
    if (hasUpper) varietyCount++;
    if (hasLower) varietyCount++;
    if (hasDigit) varietyCount++;
    if (hasSymbol) varietyCount++;

    score += varietyCount * 0.1;

    if (varietyCount < 3 && feedback.isEmpty) {
      feedback = 'Add more character variety (uppercase, lowercase, numbers, symbols)';
    }

    // Entropy score (max 0.3)
    final uniqueChars = password.split('').toSet().length;
    final entropyScore = (uniqueChars / password.length).clamp(0.0, 1.0);
    score += entropyScore * 0.3;

    // Penalize common patterns
    if (RegExp(r'(.)\1{2,}').hasMatch(password)) {
      // Repeated characters
      score -= 0.1;
      if (feedback.isEmpty) feedback = 'Avoid repeating characters';
    }

    if (RegExp(r'(012|123|234|345|456|567|678|789|890|abc|bcd|cde)').hasMatch(password.toLowerCase())) {
      // Sequential characters
      score -= 0.1;
      if (feedback.isEmpty) feedback = 'Avoid sequential patterns';
    }

    score = score.clamp(0.0, 1.0);

    // Determine strength level
    PasswordStrength strength;
    if (score >= 0.8) {
      strength = PasswordStrength.veryStrong;
      if (feedback.isEmpty) feedback = 'Excellent! Very strong password';
    } else if (score >= 0.6) {
      strength = PasswordStrength.strong;
      if (feedback.isEmpty) feedback = 'Good! Strong password';
    } else if (score >= 0.4) {
      strength = PasswordStrength.fair;
      if (feedback.isEmpty) feedback = 'Fair password, could be stronger';
    } else if (score >= 0.2) {
      strength = PasswordStrength.weak;
      if (feedback.isEmpty) feedback = 'Weak password, needs improvement';
    } else {
      strength = PasswordStrength.veryWeak;
      if (feedback.isEmpty) feedback = 'Very weak password, highly vulnerable';
    }

    return PasswordStrengthResult(
      strength: strength,
      score: score,
      feedback: feedback,
    );
  }
}
