import 'dart:async';
import 'package:hive/hive.dart';
import 'package:collection/collection.dart';

import '../models/clip_item.dart';
import '../services/categorizer.dart';

class ClipRepository {
  static const boxName = 'clips_box';
  Box<ClipItem>? _box;
  final _ctrl = StreamController<List<ClipItem>>.broadcast();

  Future<Box<ClipItem>> _getBox() async {
    _box ??= await Hive.openBox<ClipItem>(boxName);
    return _box!;
  }

  Stream<List<ClipItem>> watchAll() => _ctrl.stream;

  Future<List<ClipItem>> loadAll() async {
    final box = await _getBox();
    final items = box.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  Future<void> addFromClipboardText(String content, {int? historyLimit}) async {
    final box = await _getBox();
    final item = ClipItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      content: content,
      category: Categorizer.categorize(content),
      timestamp: DateTime.now(),
    );
    await box.put(item.id, item);

    // Trim history: keep favorites always; cap non-favorites to historyLimit
    if (historyLimit != null && historyLimit > 0) {
      final all = box.values.toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      final nonFavs = all.where((e) => !e.isFavorite).toList();
      if (nonFavs.length > historyLimit) {
        final toDelete = nonFavs
            .skip(historyLimit)
            .map((e) => e.id)
            .toList(growable: false);
        await box.deleteAll(toDelete);
      }
    }

    _emit();
  }

  Future<void> toggleFavorite(String id) async {
    final box = await _getBox();
    final item = box.get(id);
    if (item != null) {
      await box.put(id, item.copyWith(isFavorite: !item.isFavorite));
      _emit();
    }
  }

  Future<void> deleteItem(String id) async {
    final box = await _getBox();
    await box.delete(id);
    _emit();
  }

  Future<void> clearNonFavorites() async {
    final box = await _getBox();
    final keysToDelete = box.values
        .where((e) => !e.isFavorite)
        .map((e) => e.id);
    await box.deleteAll(keysToDelete);
    _emit();
  }

  Future<void> clearAll() async {
    final box = await _getBox();
    await box.clear();
    _emit();
  }

  void _emit() async {
    final box = await _getBox();
    final items = box.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    _ctrl.add(items);
  }

  Future<void> close() async {
    await _box?.close();
    await _ctrl.close();
  }
}
