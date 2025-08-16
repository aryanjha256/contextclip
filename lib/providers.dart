import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/clip_item.dart';
import 'repositories/clip_repository.dart';
import 'repositories/settings_repository.dart';
import 'services/clipboard_service.dart';

// Singletons
final clipRepoProvider = Provider<ClipRepository>((ref) => ClipRepository());
final settingsRepoProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(),
);

// Clipboard Service lifecycle tied to ProviderContainer
final clipboardServiceProvider = Provider<ClipboardService>((ref) {
  final repo = ref.read(clipRepoProvider);
  final settings = ref.read(settingsRepoProvider);

  final service = ClipboardService(
    onNewText: (text) async {
      final limit = await settings.getHistoryLimit();
      await repo.addFromClipboardText(text, historyLimit: limit);
    },
  );

  ref.onDispose(() async {
    await service.stop();
  });
  return service;
});

// App boot: initialize stream and optionally start listener
final appBootProvider = FutureProvider<void>((ref) async {
  final repo = ref.read(clipRepoProvider);
  // emit initial
  await repo.loadAll().then((_) => repo.watchAll());
  // start listener based on settings
  final settings = ref.read(settingsRepoProvider);
  final enabled = await settings.isListenerEnabled();
  final service = ref.read(clipboardServiceProvider);
  if (enabled) await service.start();
});

// Stream of all clips
final clipsStreamProvider = StreamProvider<List<ClipItem>>((ref) async* {
  final repo = ref.read(clipRepoProvider);
  // initial
  final initial = await repo.loadAll();
  yield initial;
  // updates
  yield* repo.watchAll();
});

// UI state providers
final searchQueryProvider = StateProvider<String>((ref) => '');
final categoryFilterProvider = StateProvider<ClipCategory?>((ref) => null);
final favoritesOnlyProvider = StateProvider<bool>((ref) => false);

// Derived list with filters
final filteredClipsProvider = Provider<List<ClipItem>>((ref) {
  final asyncList = ref.watch(clipsStreamProvider);
  final q = ref.watch(searchQueryProvider);
  final cat = ref.watch(categoryFilterProvider);
  final favOnly = ref.watch(favoritesOnlyProvider);

  return asyncList.maybeWhen(
    data: (items) {
      return items.where((e) {
        if (favOnly && !e.isFavorite) return false;
        if (cat != null && e.category != cat) return false;
        if (q.isNotEmpty) {
          final s = q.toLowerCase();
          return e.content.toLowerCase().contains(s);
        }
        return true;
      }).toList();
    },
    orElse: () => const [],
  );
});

// Commands
final copyCommandProvider = Provider((ref) {
  return (String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  };
});

final toggleFavoriteCommandProvider = Provider((ref) {
  final repo = ref.read(clipRepoProvider);
  return (String id) => repo.toggleFavorite(id);
});

final deleteClipCommandProvider = Provider((ref) {
  final repo = ref.read(clipRepoProvider);
  return (String id) => repo.deleteItem(id);
});

final clearNonFavsCommandProvider = Provider((ref) {
  final repo = ref.read(clipRepoProvider);
  return () => repo.clearNonFavorites();
});

final clearAllCommandProvider = Provider((ref) {
  final repo = ref.read(clipRepoProvider);
  return () => repo.clearAll();
});

final listenerToggleProvider = FutureProvider.family<bool, bool>((
  ref,
  enable,
) async {
  final settings = ref.read(settingsRepoProvider);
  final service = ref.read(clipboardServiceProvider);
  await settings.setListenerEnabled(enable);
  if (enable) {
    await service.start();
  } else {
    await service.stop();
  }
  return enable;
});

final historyLimitProvider = FutureProvider<int>((ref) async {
  final repo = ref.read(settingsRepoProvider);
  return repo.getHistoryLimit();
});

final setHistoryLimitProvider = FutureProvider.family<void, int>((
  ref,
  value,
) async {
  final settings = ref.read(settingsRepoProvider);
  await settings.setHistoryLimit(value);
});
