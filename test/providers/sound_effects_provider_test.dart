import 'package:bear_tahan/providers/data_providers.dart';
import 'package:bear_tahan/providers/sound_effects_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeSoundEffectsPreferences extends SoundEffectsPreferences {
  FakeSoundEffectsPreferences(this.storedValue);

  bool? storedValue;
  int writeCount = 0;

  @override
  Future<bool?> readEnabled() async => storedValue;

  @override
  Future<void> writeEnabled(bool enabled) async {
    storedValue = enabled;
    writeCount++;
  }
}

void main() {
  test('uses an existing local preference without cloud migration', () async {
    final preferences = FakeSoundEffectsPreferences(false);
    final container = ProviderContainer(
      overrides: [
        soundEffectsPreferencesProvider.overrideWithValue(preferences),
        parentIdProvider.overrideWithValue('parent-1'),
        parentSettingsProvider.overrideWith(
          (ref) => Stream.value({'soundEffects': true}),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(await container.read(soundEffectsProvider.future), false);
    expect(preferences.writeCount, 0);
  });

  test('migrates the legacy Firestore setting once', () async {
    final preferences = FakeSoundEffectsPreferences(null);
    final container = ProviderContainer(
      overrides: [
        soundEffectsPreferencesProvider.overrideWithValue(preferences),
        parentIdProvider.overrideWithValue('parent-1'),
        parentSettingsProvider.overrideWith(
          (ref) => Stream.value({'soundEffects': false}),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(await container.read(soundEffectsProvider.future), false);
    expect(preferences.storedValue, false);
    expect(preferences.writeCount, 1);
  });

  test('updates provider state and local storage together', () async {
    final preferences = FakeSoundEffectsPreferences(true);
    final container = ProviderContainer(
      overrides: [
        soundEffectsPreferencesProvider.overrideWithValue(preferences),
      ],
    );
    addTearDown(container.dispose);

    expect(await container.read(soundEffectsProvider.future), true);
    await container.read(soundEffectsProvider.notifier).setEnabled(false);

    expect(container.read(soundEffectsProvider).value, false);
    expect(preferences.storedValue, false);
  });
}
