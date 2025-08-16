import '../models/clip_item.dart';

class Categorizer {
  static final _link = RegExp(
    r'^(https?:\/\/)?([^\s]+\.)+[^\s]{2,}([\/?#][^\s]*)?$',
    caseSensitive: false,
  );
  static final _email = RegExp(
    r'^[\w\.\-+]+@([\w\-]+\.)+[A-Za-z]{2,}$',
    caseSensitive: false,
  );
  static final _phone = RegExp(r'^\+?[\d\s().-]{7,}$');
  static final _codeHints = RegExp(r'[{};=()<>]|class\s+\w+|function\s*\(');

  static ClipCategory categorize(String text) {
    final t = text.trim();
    if (t.isEmpty) return ClipCategory.note;
    if (_email.hasMatch(t)) return ClipCategory.email;
    if (_link.hasMatch(t)) return ClipCategory.link;
    if (_phone.hasMatch(t)) return ClipCategory.phone;
    if (_codeHints.hasMatch(t) || _looksLikeCodeBlock(t)) {
      return ClipCategory.code;
    }
    return ClipCategory.note;
  }

  static bool _looksLikeCodeBlock(String t) {
    if (t.contains('\n')) {
      final lines = t.split('\n');
      final codey = lines.where(
        (l) => l.trim().endsWith(';') || l.contains('{'),
      );
      return codey.length >= (lines.length / 3); // heuristic
    }
    return false;
  }
}
