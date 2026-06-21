import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsStore {
  static const defaultBackendUrl = kIsWeb ? 'http://localhost:5000' : 'http://10.0.2.2:5000';
  static const _backendUrlKey = 'backend_base_url';

  Future<String> getBackendUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_backendUrlKey) ?? defaultBackendUrl;
  }

  Future<void> saveBackendUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_backendUrlKey, normalizeBackendUrl(url));
  }

  static const _assessmentNotificationsKey = 'assessment_notifications_enabled';

  Future<bool> getAssessmentNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_assessmentNotificationsKey) ?? true;
  }

  Future<void> saveAssessmentNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_assessmentNotificationsKey, value);
  }

  static const _offlineCacheKey = 'offline_cache_enabled';

  Future<bool> getOfflineCacheEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_offlineCacheKey) ?? false;
  }

  Future<void> saveOfflineCacheEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_offlineCacheKey, value);
  }

  static const _monthlyImpactReportsKey = 'monthly_impact_reports_enabled';

  Future<bool> getMonthlyImpactReportsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_monthlyImpactReportsKey) ?? false;
  }

  Future<void> saveMonthlyImpactReportsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_monthlyImpactReportsKey, value);
  }

  static const _themePreferenceKey = 'theme_preference';

  Future<String> getThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themePreferenceKey) ?? 'system';
  }

  Future<void> saveThemePreference(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themePreferenceKey, value);
  }

  static String normalizeBackendUrl(String value) {
    var normalized = value.trim();
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }
}

