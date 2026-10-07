import 'package:flutter_test/flutter_test.dart';
import 'package:note_app/app.dart';

void main() {
  test('seeds only fresh accounts without welcome', () {
    expect(
      shouldSeedWelcome(
        done: false,
        force: false,
        hasNotes: false,
        hasWelcome: false,
      ),
      isTrue,
    );
  });

  test('skips when flag set', () {
    expect(
      shouldSeedWelcome(
        done: true,
        force: false,
        hasNotes: false,
        hasWelcome: false,
      ),
      isFalse,
    );
  });

  test('skips when notes exist', () {
    expect(
      shouldSeedWelcome(
        done: false,
        force: false,
        hasNotes: true,
        hasWelcome: false,
      ),
      isFalse,
    );
  });

  test('skips when welcome already present', () {
    expect(
      shouldSeedWelcome(
        done: false,
        force: false,
        hasNotes: true,
        hasWelcome: true,
      ),
      isFalse,
    );
  });

  test('force always reseeds', () {
    expect(
      shouldSeedWelcome(
        done: true,
        force: true,
        hasNotes: true,
        hasWelcome: true,
      ),
      isTrue,
    );
  });
}
