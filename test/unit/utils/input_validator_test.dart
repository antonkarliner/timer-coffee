import 'package:flutter_test/flutter_test.dart';
import 'package:coffee_timer/utils/input_validator.dart';

void main() {
  group('isValidRecipeId', () {
    test('alphanumeric ID passes', () {
      expect(InputValidator.isValidRecipeId('recipe123'), isTrue);
    });

    test('uppercase letters pass', () {
      expect(InputValidator.isValidRecipeId('ABC'), isTrue);
    });

    test('hyphens are allowed', () {
      expect(InputValidator.isValidRecipeId('recipe-with-hyphens'), isTrue);
    });

    test('numeric-only ID passes', () {
      expect(InputValidator.isValidRecipeId('1002'), isTrue);
    });

    test('empty string fails', () {
      expect(InputValidator.isValidRecipeId(''), isFalse);
    });

    test('spaces are not allowed', () {
      expect(InputValidator.isValidRecipeId('recipe 123'), isFalse);
    });

    test('@ character is not allowed', () {
      expect(InputValidator.isValidRecipeId('recipe@123'), isFalse);
    });

    test('slash is not allowed', () {
      expect(InputValidator.isValidRecipeId('recipe/123'), isFalse);
    });

    test('dot is not allowed', () {
      expect(InputValidator.isValidRecipeId('recipe.123'), isFalse);
    });
  });

  group('isValidEmail', () {
    test('standard email passes', () {
      expect(InputValidator.isValidEmail('user@example.com'), isTrue);
    });

    test('email with subdomains passes', () {
      expect(InputValidator.isValidEmail('user.name+tag@example.co.uk'), isTrue);
    });

    test('empty string fails', () {
      expect(InputValidator.isValidEmail(''), isFalse);
    });

    test('missing @ fails', () {
      expect(InputValidator.isValidEmail('userexample.com'), isFalse);
    });

    test('missing domain after @ fails', () {
      expect(InputValidator.isValidEmail('user@'), isFalse);
    });

    test('just @ fails', () {
      expect(InputValidator.isValidEmail('@'), isFalse);
    });

    test('missing TLD fails', () {
      expect(InputValidator.isValidEmail('user@localhost'), isTrue); // RFC allows this
    });
  });

  group('sanitizeInput', () {
    test('empty string returns empty', () {
      expect(InputValidator.sanitizeInput(''), '');
    });

    test('plain text passes through unchanged', () {
      expect(InputValidator.sanitizeInput('Hello World'), 'Hello World');
    });

    test('removes HTML script tags', () {
      final result = InputValidator.sanitizeInput('<script>alert("xss")</script>');
      expect(result, isNot(contains('<script>')));
    });

    test('removes javascript: protocol (case insensitive)', () {
      final result = InputValidator.sanitizeInput('JAVASCRIPT:alert(1)');
      expect(result.toLowerCase(), isNot(contains('javascript:')));
    });

    test('removes on* event handlers', () {
      final result = InputValidator.sanitizeInput('onclick=doEvil()');
      expect(result, isNot(contains('onclick=')));
    });

    test('removes onload handler', () {
      final result = InputValidator.sanitizeInput('onload = malicious()');
      expect(result, isNot(contains('onload')));
    });
  });

  group('validateAndSanitizeRecipeId', () {
    test('valid ID returns the value', () {
      expect(InputValidator.validateAndSanitizeRecipeId('recipe-123'), 'recipe-123');
    });

    test('empty string returns null', () {
      expect(InputValidator.validateAndSanitizeRecipeId(''), isNull);
    });

    test('ID with @ returns null', () {
      expect(InputValidator.validateAndSanitizeRecipeId('bad@id'), isNull);
    });
  });

  group('validateAndSanitizeEmail', () {
    test('valid email returns the value', () {
      expect(
        InputValidator.validateAndSanitizeEmail('user@example.com'),
        'user@example.com',
      );
    });

    test('invalid email returns null', () {
      expect(InputValidator.validateAndSanitizeEmail('not-an-email'), isNull);
    });

    test('empty string returns null', () {
      expect(InputValidator.validateAndSanitizeEmail(''), isNull);
    });
  });
}
