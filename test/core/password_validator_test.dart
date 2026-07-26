import 'package:flutter_test/flutter_test.dart';
import 'package:n04_app/core/utils/password_validator.dart';

void main() {
  group('isStrongPassword', () {
    test('accepts a password with all four classes and length >= 8', () {
      expect(isStrongPassword('Abcd123!'), isTrue);
      expect(isStrongPassword('Str0ng@Pass'), isTrue);
    });

    test('rejects when shorter than 8 characters', () {
      expect(isStrongPassword('Ab1!def'), isFalse); // 7 chars
    });

    test('rejects when a character class is missing', () {
      expect(isStrongPassword('abcd123!'), isFalse); // no uppercase
      expect(isStrongPassword('ABCD123!'), isFalse); // no lowercase
      expect(isStrongPassword('Abcdefg!'), isFalse); // no digit
      expect(isStrongPassword('Abcd1234'), isFalse); // no special char
    });

    test('rejects empty', () {
      expect(isStrongPassword(''), isFalse);
    });
  });
}
