import 'dart:convert';

import 'package:experiment_sdk_flutter/types/experiment_variant.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  @protected
  final String namespace;

  @protected
  final SharedPreferences _prefs;

  @protected
  Map<String, ExperimentVariant> map = {};

  LocalStorage._({required String apiKey, required SharedPreferences prefs})
      : namespace = _getNamespace(apiKey),
        _prefs = prefs;

  static Future<LocalStorage> create({required String apiKey}) async {
    final prefs = await SharedPreferences.getInstance();
    final storage = LocalStorage._(apiKey: apiKey, prefs: prefs);
    await storage._load();
    return storage;
  }

  ExperimentVariant? get(String key) {
    return map[key];
  }

  Map<String, ExperimentVariant> getAll() {
    return Map<String, ExperimentVariant>.from(map);
  }

  Future<void> replaceAll(Map<String, ExperimentVariant> newMap) async {
    map = Map<String, ExperimentVariant>.from(newMap);
    await _save();
  }

  Future<void> _load() async {
    final keys = _prefs.getKeys().where((key) => key.startsWith(namespace));
    Map<String, ExperimentVariant> newMap = {};

    for (String key in keys) {
      dynamic value = _prefs.get(key);

      // Strip the namespace prefix to get the original key
      final unprefixedKey =
          key.substring(namespace.length + 1); // +1 for the dash
      newMap[unprefixedKey] = ExperimentVariant.fromMap(jsonDecode(value));
    }

    map = newMap;
  }

  Future<void> _save() async {
    final futures = <Future<bool>>[];
    map.forEach((key, value) {
      final prefixedKey = '$namespace-$key';
      futures.add(_prefs.setString(prefixedKey, value.toJsonAsString()));
    });
    await Future.wait(futures);
  }

  static String _getNamespace(String apiKey) {
    final apiKeyToSubstring = apiKey.length > 6 ? apiKey : 'default-api-key';
    String shortApiKey = apiKeyToSubstring.substring(
      apiKeyToSubstring.length - 6,
    );

    return 'ampli-$shortApiKey';
  }
}
