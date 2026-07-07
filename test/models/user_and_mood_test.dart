import 'package:flutter_test/flutter_test.dart';
import 'package:n04_app/models/app_user.dart';
import 'package:n04_app/models/mood_entry.dart';

void main() {
  group('AppUser model', () {
    test('creates with required fields', () {
      final user = AppUser(
        id: 'user-1',
        email: 'test@example.com',
        displayName: 'Nguyen Van A',
        role: UserRole.user,
      );

      expect(user.photoUrl, isNull);
      expect(user.streakCount, 0);
      expect(user.createdAt, isNull);
      expect(user.isAdmin, isFalse);
    });

    test('toMap produces correct keys', () {
      final user = AppUser(
        id: 'user-1',
        email: 'test@example.com',
        displayName: 'Nguyen Van A',
        role: UserRole.admin,
        streakCount: 7,
      );

      final map = user.toMap();
      expect(map['id'], 'user-1');
      expect(map['email'], 'test@example.com');
      expect(map['full_name'], 'Nguyen Van A');
      expect(map['role'], 'admin');
      expect(map['streak_count'], 7);
    });

    test('fromMap parses Supabase row', () {
      final data = {
        'id': 'user-123',
        'email': 'user@email.com',
        'full_name': 'Tran Thi B',
        'avatar_url': 'https://example.com/avatar.png',
        'role': 'user',
        'streak_count': 14,
        'created_at': '2024-01-01T00:00:00.000',
      };

      final user = AppUser.fromMap(data);
      expect(user.id, 'user-123');
      expect(user.email, 'user@email.com');
      expect(user.displayName, 'Tran Thi B');
      expect(user.photoUrl, 'https://example.com/avatar.png');
      expect(user.role, UserRole.user);
      expect(user.streakCount, 14);
      expect(user.createdAt, isA<DateTime>());
    });

    test('fromMap handles missing role defaults to user', () {
      final data = {
        'id': 'user-1',
        'email': 'test@test.com',
        'full_name': 'Test User',
      };

      final user = AppUser.fromMap(data);
      expect(user.role, UserRole.user);
    });

    test('copyWith updates specified fields', () {
      final original = AppUser(
        id: 'user-1',
        email: 'old@test.com',
        displayName: 'Old Name',
        role: UserRole.user,
        streakCount: 0,
      );

      final copied = original.copyWith(
        displayName: 'New Name',
        streakCount: 5,
        photoUrl: 'https://example.com/new.png',
      );

      expect(copied.displayName, 'New Name');
      expect(copied.streakCount, 5);
      expect(copied.photoUrl, 'https://example.com/new.png');
      expect(copied.id, 'user-1'); // unchanged
      expect(copied.email, 'old@test.com'); // unchanged
    });

    test('isAdmin returns true for admin role', () {
      final admin = AppUser(
        id: 'admin-1',
        email: 'admin@test.com',
        displayName: 'Admin',
        role: UserRole.admin,
      );

      expect(admin.isAdmin, isTrue);

      final user = AppUser(
        id: 'user-1',
        email: 'user@test.com',
        displayName: 'User',
        role: UserRole.user,
      );

      expect(user.isAdmin, isFalse);
    });
  });

  group('UserRole enum', () {
    test('has two values', () {
      expect(UserRole.values.length, 2);
    });

    test('value strings are correct', () {
      expect(UserRole.admin.value, 'admin');
      expect(UserRole.user.value, 'user');
    });

    test('fromString parses correctly', () {
      expect(UserRole.fromString('admin'), UserRole.admin);
      expect(UserRole.fromString('user'), UserRole.user);
    });

    test('fromString defaults to user for unknown value', () {
      expect(UserRole.fromString('unknown'), UserRole.user);
    });

    test('helper getters work', () {
      expect(UserRole.admin.isAdmin, isTrue);
      expect(UserRole.admin.isUser, isFalse);

      expect(UserRole.user.isUser, isTrue);
      expect(UserRole.user.isAdmin, isFalse);
    });

    test('toString returns value string', () {
      expect(UserRole.admin.toString(), 'admin');
      expect(UserRole.user.toString(), 'user');
    });
  });

  group('MoodEntry model', () {
    test('creates with required fields', () {
      final entry = MoodEntry(
        entryId: 'entry-1',
        userId: 'user-1',
        moodLevel: 4,
        timestamp: DateTime(2024, 4, 1, 10, 0),
      );

      expect(entry.note, isNull);
      expect(entry.emotionFactors, isEmpty);
      expect(entry.tags, isEmpty);
    });

    test('creates with optional fields', () {
      final entry = MoodEntry(
        entryId: 'entry-1',
        userId: 'user-1',
        moodLevel: 3,
        note: 'Feeling okay today',
        timestamp: DateTime(2024, 4, 1, 10, 0),
        emotionFactors: ['work', 'sleep'],
        tags: ['morning'],
      );

      expect(entry.note, 'Feeling okay today');
      expect(entry.emotionFactors, ['work', 'sleep']);
      expect(entry.tags, ['morning']);
    });

    test('toMap produces correct keys', () {
      final entry = MoodEntry(
        entryId: 'entry-1',
        userId: 'user-1',
        moodLevel: 5,
        note: 'Great day!',
        timestamp: DateTime(2024, 4, 1),
        emotionFactors: ['exercise', 'family'],
        tags: ['weekend'],
      );

      final map = entry.toMap();
      expect(map['id'], 'entry-1');
      expect(map['user_id'], 'user-1');
      expect(map['mood_score'], 5);
      expect(map['note'], 'Great day!');
      expect(map['emotion_factors'], ['exercise', 'family']);
      expect(map['tags'], ['weekend']);
    });

    test('fromMap parses Supabase row', () {
      final data = {
        'id': 'entry-123',
        'user_id': 'user-1',
        'mood_score': 3,
        'note': 'Average day',
        'created_at': '2024-04-01T10:00:00.000',
        'emotion_factors': ['work', 'stress'],
        'tags': ['weekday'],
      };

      final entry = MoodEntry.fromMap(data);
      expect(entry.entryId, 'entry-123');
      expect(entry.userId, 'user-1');
      expect(entry.moodLevel, 3);
      expect(entry.note, 'Average day');
      expect(entry.emotionFactors, ['work', 'stress']);
      expect(entry.tags, ['weekday']);
    });

    test('fromMap handles null optional fields', () {
      final data = {
        'id': 'entry-1',
        'user_id': 'user-1',
        'mood_score': 4,
        'note': null,
        'created_at': '2024-04-01T10:00:00.000',
        'emotion_factors': null,
        'tags': null,
      };

      final entry = MoodEntry.fromMap(data);
      expect(entry.note, isNull);
      expect(entry.emotionFactors, isEmpty);
      expect(entry.tags, isEmpty);
    });

    test('fromMap handles missing fields with defaults', () {
      final data = {
        'id': null,
        'user_id': null,
        'mood_score': null,
        'created_at': null,
      };

      final entry = MoodEntry.fromMap(data);
      expect(entry.entryId, '');
      expect(entry.userId, '');
      expect(entry.moodLevel, 3); // default
    });

    test('getAverageMood returns correct average', () {
      final entries = [
        MoodEntry(entryId: '1', userId: 'u1', moodLevel: 2, timestamp: DateTime.now()),
        MoodEntry(entryId: '2', userId: 'u1', moodLevel: 4, timestamp: DateTime.now()),
        MoodEntry(entryId: '3', userId: 'u1', moodLevel: 3, timestamp: DateTime.now()),
      ];

      final avg = MoodEntry.getAverageMood(entries);
      expect(avg, 3.0); // (2+4+3)/3 = 3.0
    });

    test('getAverageMood returns 0.0 for empty list', () {
      expect(MoodEntry.getAverageMood([]), 0.0);
    });

    test('getAverageMood handles single entry', () {
      final entries = [
        MoodEntry(entryId: '1', userId: 'u1', moodLevel: 5, timestamp: DateTime.now()),
      ];

      expect(MoodEntry.getAverageMood(entries), 5.0);
    });
  });
}
