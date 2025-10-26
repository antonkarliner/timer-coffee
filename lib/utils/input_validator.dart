/// Utility class for validating and sanitizing user inputs
class InputValidator {
  // Private constructor to prevent instantiation
  InputValidator._();

  /// Validates recipe ID format (alphanumeric with hyphens)
  ///
  /// Returns true if the recipe ID is valid, false otherwise.
  /// Valid format: alphanumeric characters and hyphens only
  static bool isValidRecipeId(String id) {
    if (id.isEmpty) return false;

    // Recipe IDs should contain only alphanumeric characters and hyphens
    // Pattern: ^[a-zA-Z0-9-]+$
    final RegExp recipeIdPattern = RegExp(r'^[a-zA-Z0-9-]+$');
    return recipeIdPattern.hasMatch(id);
  }

  /// Validates email format using regex
  ///
  /// Returns true if the email is valid, false otherwise.
  /// Uses a comprehensive email validation regex pattern.
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;

    // Email validation regex pattern
    // This pattern follows RFC 5322 standard for email validation
    final RegExp emailPattern = RegExp(
        r'^[a-zA-Z0-9.!#$%&\*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$');
    return emailPattern.hasMatch(email);
  }

  /// Sanitizes input by removing potentially dangerous characters
  ///
  /// Removes characters like <, >, ', ", and javascript: patterns
  /// that could be used for XSS attacks.
  ///
  /// Returns a sanitized version of the input string.
  static String sanitizeInput(String input) {
    if (input.isEmpty) return input;

    // Remove potentially dangerous characters
    String sanitized = input;

    // Remove HTML tags
    sanitized = sanitized.replaceAll(RegExp(r'<[^>]*>'), '');

    // Remove javascript: protocol
    sanitized =
        sanitized.replaceAll(RegExp(r'javascript:', caseSensitive: false), '');

    // Remove on* event handlers (onclick, onload, etc.)
    sanitized =
        sanitized.replaceAll(RegExp(r'on\w+\s*=', caseSensitive: false), '');

    // Replace potentially dangerous characters with HTML entities
    sanitized = sanitized.replaceAll('<', '<');
    sanitized = sanitized.replaceAll('>', '>');
    sanitized = sanitized.replaceAll('"', '"');
    sanitized = sanitized.replaceAll("'", '&#39;');

    return sanitized;
  }

  /// Validates and sanitizes a recipe ID
  ///
  /// Returns the sanitized recipe ID if valid, null otherwise.
  static String? validateAndSanitizeRecipeId(String id) {
    final sanitizedId = sanitizeInput(id);
    return isValidRecipeId(sanitizedId) ? sanitizedId : null;
  }

  /// Validates and sanitizes an email
  ///
  /// Returns the sanitized email if valid, null otherwise.
  static String? validateAndSanitizeEmail(String email) {
    final sanitizedEmail = sanitizeInput(email);
    return isValidEmail(sanitizedEmail) ? sanitizedEmail : null;
  }
}
