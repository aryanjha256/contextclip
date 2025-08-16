import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  static const _historyLimitKey = 'history_limit';
  static const _listenerEnabledKey = 'listener_enabled';

  Future<int> getHistoryLimit() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_historyLimitKey) ?? 100;
    // Default: keep last 100 non-favorite items
  }

  Future<void> setHistoryLimit(int value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_historyLimitKey, value);
  }

  Future<bool> isListenerEnabled() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_listenerEnabledKey) ?? true;
  }

  Future<void> setListenerEnabled(bool enabled) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_listenerEnabledKey, enabled);
  }
}
