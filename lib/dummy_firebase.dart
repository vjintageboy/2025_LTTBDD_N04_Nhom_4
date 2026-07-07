import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'models/streak.dart';
import 'models/mood_entry.dart';
import 'models/meditation.dart';

// Mock FirestoreService
class FirestoreService {
  Future<dynamic> getMeditationLibrary() async => [];
  Future<dynamic> getArticles() async => [];
  Future<void> createUser(dynamic user) async {}
  Future<dynamic> getUser(String id) async => null;
  Future<void> updateUser(String id, Map<String, dynamic> data) async {}
  Future<void> logMood(dynamic entry) async {}
  Stream<dynamic> getMoodHistory(String userId) => const Stream.empty();
  Stream<dynamic> getNewsPosts() => const Stream.empty();
  Future<void> updateMeditation(String id, Map<String, dynamic> data) async {}
  Future<void> addMeditation(dynamic m) async {}
  Future<void> deleteMeditation(String id) async {}

  
  // Streak Methods
  Future<void> recalculateStreak(String uid) async {}
  Future<dynamic> getOrCreateStreak(String uid) async => null;
  Future<List<DateTime>> getUserActivityDates(String uid, [DateTime? start, DateTime? end]) async => [];
  Stream<Streak?> streamStreak(String uid) => const Stream.empty();

  // Mood Methods
  Future<List<MoodEntry>> getMoodEntriesForPeriod({required String userId, required DateTime start, required DateTime end}) async => [];
  Stream<List<MoodEntry>> streamMoodEntries(String uid) => const Stream.empty();
  Future<void> createMoodEntry(dynamic entry) async {}
  Future<void> updateMoodEntry(String id, Map<String, dynamic> data) async {}
  Future<void> deleteMoodEntry(String id) async {}
  Future<List<MoodEntry>> getMoodEntries(String uid) async => [];

  // Admin / User Methods
  Future<void> updateUserRole(String uid, dynamic role) async {}
  Future<void> createOrUpdateUser({required String uid, required String email, required String displayName, String? photoUrl, required dynamic role}) async {}
  Future<bool> isAdmin(String uid) async => false;
  Future<dynamic> getUserProfile(String uid) async => null;

  // Meditation Methods
  Future<void> createMeditation(dynamic m) async {}
  Future<List<Meditation>> getAllMeditations() async => [];
  Stream<List<Meditation>> streamMeditations() => const Stream.empty();
}

class FirebaseFirestore {
  static final FirebaseFirestore instance = FirebaseFirestore();
  DummyCollection collection(String path) => DummyCollection();
  Query collectionGroup(String path) => Query();
  Future<void> runTransaction(dynamic action) async {}
  DummyBatch batch() => DummyBatch();
}

class DummyCollection extends Query {
  DummyDocument doc([String? path]) => DummyDocument();
  Future<DocumentReference> add(Map<String, dynamic> data) async =>
      DummyDocument();
}

class Query {
  Query where(
    dynamic field, {
    dynamic isEqualTo,
    dynamic isGreaterThan,
    dynamic isLessThan,
    dynamic isGreaterThanOrEqualTo,
    dynamic isLessThanOrEqualTo,
    dynamic arrayContains,
    dynamic whereIn,
  }) => this;
  Query orderBy(dynamic field, {bool descending = false}) => this;
  Query limit(int length) => this;
  Stream<QuerySnapshot> snapshots() => const Stream.empty();
  Future<QuerySnapshot> get() async => QuerySnapshot();
}

class DocumentReference {
  String get id => 'dummy_id';
  Future<DocumentSnapshot> get() async => DocumentSnapshot();
  Future<void> set(Map<String, dynamic> data, [dynamic options]) async {}
  Future<void> update(Map<String, dynamic> data) async {}
  Future<void> delete() async {}
  Stream<DocumentSnapshot> snapshots() => const Stream.empty();
  DummyCollection collection(String path) => DummyCollection();
}

class DummyDocument extends DocumentReference {}

class DummyBatch {
  void set(
    DocumentReference ref,
    Map<String, dynamic> data, [
    dynamic options,
  ]) {}
  void update(DocumentReference ref, Map<String, dynamic> data) {}
  void delete(DocumentReference ref) {}
  Future<void> commit() async {}
}

class SetOptions {
  final bool merge;
  const SetOptions({this.merge = false});
}

class DocumentSnapshot {
  bool get exists => true;
  String get id => 'dummy_id';
  Map<String, dynamic> data() => {};
  dynamic get(String field) => null;
  DocumentReference get reference => DummyDocument();
}

class QuerySnapshot {
  List<DocumentSnapshot> get docs => [];
  List<DocumentChange> get docChanges => [];
}

class DocumentChange {
  DocumentSnapshot get doc => DocumentSnapshot();
  DocumentChangeType get type => DocumentChangeType.added;
}

enum DocumentChangeType { added, modified, removed }

class FirebaseAuth {
  static final FirebaseAuth instance = FirebaseAuth();
  User? get currentUser {
    final sbUser = sb.Supabase.instance.client.auth.currentUser;
    return sbUser != null ? User() : null;
  }
  Stream<dynamic> authStateChanges() => const Stream.empty();
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async => null;
  Future<UserCredential?> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async => null;
  Future<void> signOut() async {}
  Future<void> sendPasswordResetEmail({required String email}) async {}
}

class UserCredential {
  User? get user => User();
}

class User {
  // Proxy sang Supabase user thực tế
  sb.User? get _sbUser => sb.Supabase.instance.client.auth.currentUser;

  String get uid => _sbUser?.id ?? '';
  String? get email => _sbUser?.email;
  String? get displayName =>
      _sbUser?.userMetadata?['full_name'] as String? ?? _sbUser?.email?.split('@').first;
  String? get photoURL => _sbUser?.userMetadata?['avatar_url'] as String?;

  Future<void> updateDisplayName(String? name) async {}
  Future<void> verifyBeforeUpdateEmail(String email) async {}
  Future<void> reload() async {}
}

class FirebaseAuthException implements Exception {
  final String message;
  final String code;
  FirebaseAuthException(this.code, [this.message = '']);
}

class FirebaseException implements Exception {
  final String message;
  final String code;
  final String plugin;
  FirebaseException({this.plugin = '', this.code = '', this.message = ''});
}

class FieldValue {
  static dynamic serverTimestamp() => DateTime.now();
  static dynamic serverDateTime() => DateTime.now();
  static dynamic arrayUnion(List elements) => elements;
  static dynamic arrayRemove(List elements) => elements;
  static dynamic increment(num value) => value;
  static dynamic delete() => null;
}

class Timestamp {
  final int seconds;
  final int nanoseconds;
  Timestamp(this.seconds, this.nanoseconds);

  static Timestamp now() => Timestamp(0, 0);
  DateTime toDate() => DateTime.now();
  static Timestamp fromDate(DateTime date) => Timestamp(
    date.millisecondsSinceEpoch ~/ 1000,
    (date.millisecondsSinceEpoch % 1000) * 1000000,
  );
}

extension DummyDateTimeExt on DateTime {
  DateTime toDate() => this;
}
