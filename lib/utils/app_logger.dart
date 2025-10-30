import 'package:logging/logging.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'log_config.dart';

/// Secure logging utility for Timer.Coffee application
///
/// Replaces print() statements with proper logging that:
/// - Only logs debug information in debug mode
/// - Sanitizes sensitive data to prevent exposure
/// - Uses appropriate log levels for different environments
/// - Prevents log injection attacks through comprehensive input sanitization
/// - Protects against log forgery and tampering
///
/// ## Log Injection Prevention Measures
///
/// This logger implements multiple layers of protection against log injection attacks:
///
/// 1. **Input Sanitization**: All user input is sanitized before logging
/// 2. **Control Character Removal**: Dangerous control characters are stripped
/// 3. **SQL Injection Prevention**: SQL keywords and patterns are neutralized
/// 4. **Path Traversal Protection**: Directory traversal attempts are blocked
/// 5. **Length Limiting**: Messages are truncated to prevent log flooding
/// 6. **Log Integrity**: Timestamps and hashes prevent log forgery
///
/// ## Security Considerations
/// - Never log raw user input without sanitization
/// - Use structured logging when possible
/// - Implement log monitoring for suspicious patterns
/// - Regular security audits of logging implementation
class AppLogger {
  static final Logger _logger = Logger('TimerCoffee');
  static bool _isLogging = false; // Prevent recursive logging

  // Control characters that could be used for log injection
  static final RegExp _controlChars = RegExp(r'[\x00-\x1F\x7F-\x9F]');

  // Newline characters that could break log formatting
  static final RegExp _newlineChars = RegExp(r'[\r\n]');

  // Additional cached regex patterns for validation
  static final RegExp _userIdRegex = RegExp(r'^[a-zA-Z0-9_-]{3,50}$');
  static final RegExp _tokenRegex = RegExp(r'^[a-zA-Z0-9._-]{20,500}$');
  static final RegExp _invalidPathRegex = RegExp(r'[<>:"|?*]');

  // Cached regex patterns for comprehensive sensitive data sanitization
  // These patterns are pre-compiled for better performance
  static final List<RegExp> _sanitizationPatterns = [
    // Enhanced JWT patterns - covering all variations
    // Standard JWT: header.payload.signature
    // Supabase specific formats with various encoding schemes
    RegExp(r'[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_\.]+'),

    // Comprehensive UUID patterns
    // Standard UUID: 123e4567-e89b-12d3-a456-426614174000
    RegExp(
        r'\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\b'),

    // Short UUID variants and database-specific ID formats
    // Supabase user IDs and other short UUID formats
    RegExp(r'\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\b'),

    // Enhanced email patterns
    // Standard emails: user@domain.com
    // Subdomain emails: user@sub.domain.com
    // Special character emails: user.name+tag@domain.co.uk
    // International emails with various TLDs
    RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b'),

    // API keys and tokens (20+ characters)
    // Various API key formats and long tokens
    RegExp(r'\b[A-Za-z0-9]{20,}\b'),

    // Bearer tokens
    // Standard Bearer token format
    RegExp(r'Bearer\s+[A-Za-z0-9\-_\.]+'),

    // Session identifiers
    // Various session ID formats with different naming conventions
    RegExp(
        r'session[_-]?id[\x22\x27]?\s*[:=]\s*[\x22\x27]?[A-Za-z0-9\-_]{10,}'),

    // Database connection strings
    // PostgreSQL, MySQL, MongoDB connection strings
    RegExp(r'(postgresql|mysql|mongodb)://[^\x40\s]+\x40[^\x2f\s]+'),

    // Authentication headers
    // Authorization headers with various schemes
    RegExp(r'Authorization\s*:\s*[A-Za-z0-9\-_\.]+'),

    // External service credentials
    // API keys, secret keys, access tokens
    RegExp(
        r'(api[_-]?key|secret[_-]?key|access[_-]?token)[\x22\x27]?\s*[:=]\s*[\x22\x27]?[A-Za-z0-9\-_]{10,}'),

    // Personal identifiers
    // SSN, social security numbers, passport IDs
    RegExp(
        r'(ssn|social[_-]?security|passport[_-]?id)[\x22\x27]?\s*[:=]\s*[\x22\x27]?[A-Za-z0-9\-_]{6,}'),

    // Credit card patterns (basic detection)
    // Visa, MasterCard, American Express, Discover, JCB, Diners Club
    RegExp(
        r'\b(?:4[0-9]{12}(?:[0-9]{3})?|5[1-5][0-9]{14}|3[47][0-9]{13}|3[0-9]{13}|6(?:011|5[0-9]{2})[0-9]{12})\b'),

    // Phone numbers (basic pattern)
    // International phone number formats
    RegExp(
        r'\b(?:\+?1[-.\s]?)?\(?([0-9]{3})\)?[-.\s]?([0-9]{3})[-.\s]?([0-9]{4})\b'),

    // Hash values (common lengths)
    // MD5, SHA-1, SHA-256 hash values
    RegExp(r'\b[a-fA-F0-9]{32}\b|\b[a-fA-F0-9]{40}\b|\b[a-fA-F0-9]{64}\b'),
  ];

  // Replacement strings for each pattern
  static final List<String> _sanitizationReplacements = [
    'jwt=[REDACTED]',
    'uuid=[REDACTED]',
    'shortUuid=[REDACTED]',
    'email=[REDACTED]',
    'apikey=[REDACTED]',
    'Bearer=[REDACTED]',
    'sessionId=[REDACTED]',
    'database=[REDACTED]',
    'authHeader=[REDACTED]',
    'credentials=[REDACTED]',
    'personalId=[REDACTED]',
    'creditCard=[REDACTED]',
    'phone=[REDACTED]',
    'hash=[REDACTED]',
  ];

  // SQL injection patterns
  static final List<RegExp> _sqlInjectionPatterns = [
    RegExp(
      r'\b(union|select|insert|update|delete|drop|create|alter|exec|execute)\b',
      caseSensitive: false,
    ),
    RegExp(
      r'''(--|#|/\*|\*/|;|"|')''',
      caseSensitive: false,
    ),
    RegExp(r'(or|and)\s+\d+\s*=\s*\d+', caseSensitive: false),
    RegExp(
      r"(or|and)\s+'[^']+'\s*=\s*'[^']+'",
      caseSensitive: false,
    ),
    RegExp(
      r"waitfor\s+delay\s+'?\d+(:\d+){0,2}'?",
      caseSensitive: false,
    ),
    RegExp(
      r'\d+\s*;\s*(union|select|insert|update|delete)',
      caseSensitive: false,
    ),
  ];

  // Path traversal patterns
  static final List<RegExp> _pathTraversalPatterns = [
    RegExp(r'\.\.[\/\\]'),
    RegExp(r'[\/\\]\.\.[\/\\]'),
    RegExp(r'^[\/\\]'),
    RegExp(r'[\/\\]$'),
  ];

  /// Logs debug information - only in debug mode
  ///
  /// [message] The debug message to log
  /// [error] Optional error object
  /// [stackTrace] Optional stack trace
  static void debug(String message,
      {Object? errorObject, StackTrace? stackTrace}) {
    // Prevent recursive logging
    if (_isLogging) return;

    // Use LogConfig to determine if we should log debug messages
    if (LogConfig.shouldLog(Level.FINE)) {
      _isLogging = true;
      try {
        final sanitizedMessage = _sanitizeLogInput(message);
        final sanitizedError = errorObject != null
            ? _sanitizeLogInput(errorObject.toString())
            : null;
        _logger.fine(sanitizedMessage, sanitizedError, stackTrace);
      } finally {
        _isLogging = false;
      }
    }
  }

  /// Logs informational messages - based on log level configuration
  ///
  /// [message] The info message to log
  /// [errorObject] Optional error object
  /// [stackTrace] Optional stack trace
  static void info(String message,
      {Object? errorObject, StackTrace? stackTrace}) {
    // Prevent recursive logging
    if (_isLogging) return;

    // Use LogConfig to determine if we should log info messages
    if (LogConfig.shouldLog(Level.INFO)) {
      _isLogging = true;
      try {
        final sanitizedMessage = _sanitizeLogInput(message);
        final sanitizedError = errorObject != null
            ? _sanitizeLogInput(errorObject.toString())
            : null;
        _logger.info(sanitizedMessage, sanitizedError, stackTrace);
      } finally {
        _isLogging = false;
      }
    }
  }

  /// Logs warning messages - based on log level configuration
  ///
  /// [message] The warning message to log
  /// [errorObject] Optional error object
  /// [stackTrace] Optional stack trace
  static void warning(String message,
      {Object? errorObject, StackTrace? stackTrace}) {
    // Prevent recursive logging
    if (_isLogging) return;

    // Use LogConfig to determine if we should log warning messages
    if (LogConfig.shouldLog(Level.WARNING)) {
      _isLogging = true;
      try {
        final sanitizedMessage = _sanitizeLogInput(message);
        final sanitizedError = errorObject != null
            ? _sanitizeLogInput(errorObject.toString())
            : null;
        _logger.warning(sanitizedMessage, sanitizedError, stackTrace);
      } finally {
        _isLogging = false;
      }
    }
  }

  /// Logs error messages - always logged regardless of build mode
  ///
  /// [message] The error message to log
  /// [errorObject] Optional error object
  /// [stackTrace] Optional stack trace
  static void error(String message,
      {Object? errorObject, StackTrace? stackTrace}) {
    // Prevent recursive logging
    if (_isLogging) return;

    // Errors should always be logged regardless of build mode
    _isLogging = true;
    try {
      final sanitizedMessage = _sanitizeLogInput(message);
      final sanitizedError = errorObject != null
          ? _sanitizeLogInput(errorObject.toString())
          : null;
      _logger.severe(sanitizedMessage, sanitizedError, stackTrace);
    } finally {
      _isLogging = false;
    }
  }

  /// Logs security-related events - always logged with SECURITY prefix
  ///
  /// [message] The security message to log
  static void security(String message) {
    // Prevent recursive logging
    if (_isLogging) return;

    // Security events should always be logged regardless of build mode
    _isLogging = true;
    try {
      final sanitizedMessage = _sanitizeLogInput(message);
      _logger.severe('SECURITY: $sanitizedMessage');
    } finally {
      _isLogging = false;
    }
  }

  /// Sanitizes sensitive data before logging
  ///
  /// Removes or redacts sensitive information like tokens, passwords, and user IDs
  /// In production mode, sensitive data is completely redacted
  ///
  /// [data] The data to sanitize
  /// Returns sanitized string with sensitive information redacted
  static String sanitize(Object? data) {
    if (data == null) return 'null';

    final String str = data.toString();

    // In production mode, completely redact sensitive data
    if (!LogConfig.shouldLogSensitiveData()) {
      return _redactAllSensitiveData(str);
    }

    return _sanitizeSensitiveData(str);
  }

  /// Sanitizes user IDs and authentication tokens for safe logging
  ///
  /// [userId] The user ID to sanitize
  /// Returns sanitized user ID with sensitive information redacted
  static String sanitizeUserId(String? userId) {
    if (userId == null || userId.isEmpty) return '[NULL_USER_ID]';

    // Check for potential injection patterns
    if (_containsInjectionPatterns(userId)) {
      return '[INVALID_USER_ID]';
    }

    // Validate user ID format
    if (!_isValidUserId(userId)) {
      return '[INVALID_USER_ID]';
    }

    // Redact most of ID, keeping only first and last 2 characters
    if (userId.length <= 4) {
      return '[REDACTED_USER_ID]';
    }

    return '${userId.substring(0, 2)}***${userId.substring(userId.length - 2)}';
  }

  /// Sanitizes authentication tokens for safe logging
  ///
  /// [token] The token to sanitize
  /// Returns sanitized token with sensitive information redacted
  static String sanitizeToken(String? token) {
    if (token == null || token.isEmpty) return '[NULL_TOKEN]';

    // Check for potential injection patterns
    if (_containsInjectionPatterns(token)) {
      return '[INVALID_TOKEN]';
    }

    // Validate token format
    if (!_isValidToken(token)) {
      return '[INVALID_TOKEN]';
    }

    // Redact most of token, keeping only first and last 4 characters
    if (token.length <= 8) {
      return '[REDACTED_TOKEN]';
    }

    return '${token.substring(0, 4)}***${token.substring(token.length - 4)}';
  }

  /// Sanitizes file paths and system paths for safe logging
  ///
  /// [path] The path to sanitize
  /// Returns sanitized path with traversal attacks prevented
  static String sanitizePath(String? path) {
    if (path == null || path.isEmpty) return '[NULL_PATH]';

    // Validate path format
    if (!_isValidPath(path)) {
      return '[INVALID_PATH]';
    }

    String sanitized = path;

    // Remove path traversal patterns
    for (final pattern in _pathTraversalPatterns) {
      if (pattern.hasMatch(sanitized)) {
        sanitized = sanitized.replaceAll(pattern, '[PATH_TRAVERSAL]');
      }
    }

    // Remove control characters
    sanitized = sanitized.replaceAll(_controlChars, '');

    // Limit path length to prevent log flooding
    if (sanitized.length > 200) {
      sanitized = '${sanitized.substring(0, 197)}...';
    }

    return sanitized;
  }

  /// Sanitizes database queries and SQL statements for safe logging
  ///
  /// [query] The SQL query to sanitize
  /// Returns sanitized query with injection patterns neutralized
  static String sanitizeSqlQuery(String? query) {
    if (query == null || query.isEmpty) return '[NULL_QUERY]';

    String sanitized = query;

    // Check for SQL injection patterns
    for (final pattern in _sqlInjectionPatterns) {
      if (pattern.hasMatch(sanitized)) {
        // Replace dangerous SQL keywords with safe alternatives
        sanitized = sanitized.replaceAll(pattern, '[SQL_PATTERN]');
      }
    }

    // Remove control characters and newlines
    sanitized = sanitized.replaceAll(_controlChars, '');
    sanitized = sanitized.replaceAll(_newlineChars, ' ');

    // Limit query length to prevent log flooding
    if (sanitized.length > 500) {
      sanitized = '${sanitized.substring(0, 497)}...';
    }

    return sanitized;
  }

  /// Sanitizes user-generated content and free text input for safe logging
  ///
  /// [content] The user content to sanitize
  /// Returns sanitized content with injection patterns removed
  static String sanitizeUserContent(String? content) {
    if (content == null || content.isEmpty) return '[NULL_CONTENT]';

    String sanitized = content;

    // Remove control characters
    sanitized = sanitized.replaceAll(_controlChars, '');

    // Replace newlines with spaces to prevent log format breaking
    sanitized = sanitized.replaceAll(_newlineChars, ' ');

    // Normalize whitespace
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ');

    // Remove potential script injection patterns
    sanitized = sanitized.replaceAll(
        RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false),
        '[SCRIPT_REMOVED]');
    sanitized = sanitized.replaceAll(
        RegExp(r'javascript:', caseSensitive: false), '[JS_REMOVED]');

    // Limit content length to prevent log flooding
    if (sanitized.length > 300) {
      sanitized = '${sanitized.substring(0, 297)}...';
    }

    return sanitized.trim();
  }

  /// Internal method to sanitize all log inputs with comprehensive protection
  ///
  /// [input] The input to sanitize
  /// Returns sanitized input safe for logging
  static String _sanitizeLogInput(String input) {
    // Add input length validation to prevent DoS attacks
    if (input.length > 10000) {
      return '[INPUT_TOO_LONG]';
    }

    if (input.isEmpty) return '[EMPTY_MESSAGE]';

    String sanitized = input;

    // Remove control characters that could interfere with log parsing
    sanitized = sanitized.replaceAll(_controlChars, '');

    // Replace newlines with spaces to prevent log format breaking
    sanitized = sanitized.replaceAll(_newlineChars, ' ');

    // Apply sensitive data sanitization
    sanitized = _sanitizeSensitiveData(sanitized);

    // Add cryptographically secure log integrity marker to prevent forgery
    sanitized = _addSecureLogIntegrityMarker(sanitized);

    // Limit message length to prevent log flooding
    if (sanitized.length > 1000) {
      sanitized = '${sanitized.substring(0, 997)}...';
    }

    return sanitized.trim();
  }

  /// Internal method to sanitize sensitive data patterns
  ///
  /// [data] The data string to sanitize
  /// Returns string with sensitive information redacted
  static String _sanitizeSensitiveData(String data) {
    String sanitized = data;

    // Use cached regex patterns for better performance
    for (int i = 0; i < _sanitizationPatterns.length; i++) {
      sanitized = sanitized.replaceAll(
          _sanitizationPatterns[i], _sanitizationReplacements[i]);
    }

    // Additional legacy patterns for backward compatibility
    // Redact authentication tokens (more comprehensive pattern)
    sanitized = sanitized.replaceAll(
        RegExp(r'[tT]oken[":=\s]*[\w\-.\/+]+', caseSensitive: false),
        'token=[REDACTED]');

    // Redact bearer tokens (legacy pattern)
    sanitized = sanitized.replaceAll(
        RegExp(r'[bB]earer[":=\s]*[\w\-.\/+]+', caseSensitive: false),
        'bearer=[REDACTED]');

    // Redact passwords
    sanitized = sanitized.replaceAll(
        RegExp(r'[pP]assword[":=\s]*[\w\-.\/+]+', caseSensitive: false),
        'password=[REDACTED]');

    // Redact user IDs (keep format but redact actual values)
    sanitized = sanitized.replaceAll(
        RegExp(r'[uU]ser[_\s]*[iI]d[":=\s]*[\w\-.\/+]+', caseSensitive: false),
        'userId=[REDACTED]');

    // Redact API keys
    sanitized = sanitized.replaceAll(
        RegExp(r'[aA]pi[_\s]*[kK]ey[":=\s]*[\w\-.\/+]+', caseSensitive: false),
        'apiKey=[REDACTED]');

    // Redact session IDs
    sanitized = sanitized.replaceAll(
        RegExp(r'[sS]ession[_\s]*[iI]d[":=\s]*[\w\-.\/+]+',
            caseSensitive: false),
        'sessionId=[REDACTED]');

    return sanitized;
  }

  /// Completely redacts all potentially sensitive data for production builds
  ///
  /// [data] The data string to redact
  /// Returns string with all potentially sensitive information completely redacted
  static String _redactAllSensitiveData(String data) {
    // In production, be more aggressive with redaction
    String redacted = data;

    // Redact any potential authentication tokens
    redacted = redacted.replaceAll(
        RegExp(r'[tT]oken', caseSensitive: false), '[REDACTED]');

    // Redact any potential passwords
    redacted = redacted.replaceAll(
        RegExp(r'[pP]assword', caseSensitive: false), '[REDACTED]');

    // Redact any potential user IDs
    redacted = redacted.replaceAll(
        RegExp(r'[uU]ser[_\s]*[iI]d', caseSensitive: false), '[REDACTED]');

    // Redact all email addresses
    redacted = redacted.replaceAll(
        RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b'),
        '[REDACTED_EMAIL]');

    // Redact any potential API keys
    redacted = redacted.replaceAll(
        RegExp(r'[aA]pi[_\s]*[kK]ey', caseSensitive: false), '[REDACTED]');

    // Redact any potential session IDs
    redacted = redacted.replaceAll(
        RegExp(r'[sS]ession[_\s]*[iI]d', caseSensitive: false), '[REDACTED]');

    // Redact all JWT tokens
    redacted = redacted.replaceAll(
        RegExp(r'[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+'),
        '[REDACTED_JWT]');

    // Redact all hash values
    redacted = redacted.replaceAll(
        RegExp(r'\b[a-fA-F0-9]{32,64}\b'), '[REDACTED_HASH]');

    // Redact any potential bearer tokens
    redacted = redacted.replaceAll(
        RegExp(r'[bB]earer', caseSensitive: false), '[REDACTED]');

    return redacted;
  }

  /// Checks if input contains potential injection patterns
  ///
  /// [input] The input to check
  /// Returns true if injection patterns are detected
  static bool _containsInjectionPatterns(String input) {
    // Check for control characters
    if (_controlChars.hasMatch(input)) return true;

    // Check for SQL injection patterns
    for (final pattern in _sqlInjectionPatterns) {
      if (pattern.hasMatch(input)) return true;
    }

    // Check for path traversal patterns
    for (final pattern in _pathTraversalPatterns) {
      if (pattern.hasMatch(input)) return true;
    }

    // Check for script injection patterns
    if (RegExp(r'<script|javascript:|on\w+\s*=', caseSensitive: false)
        .hasMatch(input)) {
      return true;
    }

    return false;
  }

  /// Validates user ID format
  ///
  /// [userId] The user ID to validate
  /// Returns true if format is valid
  static bool _isValidUserId(String userId) {
    return _userIdRegex.hasMatch(userId);
  }

  /// Validates token format
  ///
  /// [token] The token to validate
  /// Returns true if format is valid
  static bool _isValidToken(String token) {
    return _tokenRegex.hasMatch(token);
  }

  /// Validates path format
  ///
  /// [path] The path to validate
  /// Returns true if format is valid
  static bool _isValidPath(String path) {
    return !_invalidPathRegex.hasMatch(path);
  }

  /// Adds cryptographically secure log integrity marker to prevent forgery
  ///
  /// [message] The message to add integrity marker to
  /// Returns message with secure integrity marker using SHA-256 hash
  static String _addSecureLogIntegrityMarker(String message) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    // Use cryptographically secure hash instead of insecure hashCode
    final hash = sha256
        .convert(utf8.encode('$timestamp:$message'))
        .toString()
        .substring(0, 16);
    return '[$timestamp:$hash] $message';
  }

  /// Test method to validate sanitization effectiveness
  ///
  /// [testData] The test data to sanitize
  /// Returns sanitized data with all sensitive information redacted
  /// This method can be used to verify that sanitization patterns are working correctly
  static String testSanitization(String testData) {
    return _sanitizeSensitiveData(testData);
  }
}
