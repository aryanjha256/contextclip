import 'package:clipboard_watcher/clipboard_watcher.dart';
import 'package:flutter/services.dart';

class ClipboardService extends ClipboardListener {
  final Future<void> Function(String) onNewText;
  bool _running = false;
  String? _lastText;

  ClipboardService({required this.onNewText});

  Future<void> start() async {
    if (_running) return;
    _running = true;
    clipboardWatcher.addListener(this); // lowercase instance
    clipboardWatcher.start();
  }

  Future<void> stop() async {
    if (!_running) return;
    _running = false;
    clipboardWatcher.removeListener(this);
    clipboardWatcher.stop();
  }

  @override
  Future<void> onClipboardChanged() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text?.trim();
    if (text != null && text.isNotEmpty && text != _lastText) {
      _lastText = text;
      await onNewText(text);
    }
  }
}
