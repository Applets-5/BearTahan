import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data_providers.dart';

class SoundEffectsPreferences {
  static const _enabledKey = 'soundEffectsEnabled';

  Future<bool?> readEnabled() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_enabledKey);
  }

  Future<void> writeEnabled(bool enabled) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_enabledKey, enabled);
  }
}

final soundEffectsPreferencesProvider = Provider<SoundEffectsPreferences>(
  (ref) => SoundEffectsPreferences(),
);

class SoundEffectsNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final preferences = ref.watch(soundEffectsPreferencesProvider);
    final storedValue = await preferences.readEnabled();
    if (storedValue != null) return storedValue;

    var migratedValue = true;
    final parentId = ref.read(parentIdProvider);
    if (parentId.isNotEmpty) {
      try {
        final settings = await ref.watch(parentSettingsProvider.future);
        migratedValue = settings['soundEffects'] != false;
      } catch (_) {
        migratedValue = true;
      }
    }

    await preferences.writeEnabled(migratedValue);
    return migratedValue;
  }

  Future<void> setEnabled(bool enabled) async {
    final previousValue = state.value ?? true;
    state = AsyncData(enabled);

    try {
      await ref.read(soundEffectsPreferencesProvider).writeEnabled(enabled);
    } catch (error, stackTrace) {
      state = AsyncData(previousValue);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}

final soundEffectsProvider = AsyncNotifierProvider<SoundEffectsNotifier, bool>(
  SoundEffectsNotifier.new,
);
