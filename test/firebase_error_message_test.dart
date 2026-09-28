import 'package:flutter_test/flutter_test.dart';
import 'package:spendly/services/firebase_service.dart';

void main() {
  group('FirebaseService.friendlyError', () {
    test('maps network failures without exposing SDK details', () {
      expect(
        FirebaseService.friendlyError(
          'Failed to load expenses: [cloud_firestore/unavailable]',
        ),
        contains('internet connection'),
      );
    });

    test('maps permission and session failures', () {
      expect(
        FirebaseService.friendlyError('[cloud_firestore/permission-denied]'),
        contains('deploy this project'),
      );
      expect(
        FirebaseService.friendlyError('User not logged in'),
        contains('sign in again'),
      );
    });

    test('explains missing Firestore database setup', () {
      expect(
        FirebaseService.friendlyError('[cloud_firestore/not-found]'),
        contains('Create the database in Firebase Console'),
      );
    });

    test('explains that failed queries need a composite index', () {
      expect(
        FirebaseService.friendlyError('[cloud_firestore/failed-precondition]'),
        contains('composite index'),
      );
    });

    test('hides unknown Firebase implementation details', () {
      expect(
        FirebaseService.friendlyError(
          'Failed to load data: [cloud_firestore/internal] stack trace',
        ),
        'Something went wrong while contacting Spendly. Please try again.',
      );
    });

    test('preserves human-readable authentication errors', () {
      expect(FirebaseService.friendlyError('Incorrect password'),
          'Incorrect password');
    });
  });
}
