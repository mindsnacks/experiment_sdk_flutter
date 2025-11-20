import 'dart:async';

import 'package:experiment_sdk_flutter/http_client.dart';
import 'package:experiment_sdk_flutter/local_storage.dart';
import 'package:experiment_sdk_flutter/types/experiment_config.dart';
import 'package:experiment_sdk_flutter/types/experiment_fetch_input.dart';
import 'package:experiment_sdk_flutter/types/experiment_variant.dart';

// ExperimentClient acts wrapping the APIs implementation
class ExperimentClient {
  final ExperimentConfig? _config;
  final HttpClient _httpClient;
  final LocalStorage _localStorage;

  /// Private constructor
  ExperimentClient._({
    required ExperimentConfig? config,
    required HttpClient httpClient,
    required LocalStorage localStorage,
  })  : _config = config,
        _httpClient = httpClient,
        _localStorage = localStorage;

  /// Async factory to create ExperimentClient
  static Future<ExperimentClient> create({
    required String apiKey,
    ExperimentConfig? config,
  }) async {
    final httpClient = HttpClient(
      apiKey: apiKey,
      shouldRetry: config?.retryFetchOnFailure,
    );
    final localStorage = await LocalStorage.create(apiKey: apiKey);

    return ExperimentClient._(
      config: config,
      httpClient: httpClient,
      localStorage: localStorage,
    );
  }

  // Grab the instance name from the config or use a default
  String _getInstanceName() {
    return _config?.instanceName ?? '\$default_instance';
  }

  /// Fetch an experiment or feature flag by user info
  Future<void> fetch(
      {String? userId,
      String? deviceId,
      Map<String, dynamic>? userProperties}) async {
    final context =
        await _config?.exposureTrackingProvider?.getContext(_getInstanceName());

    final input = ExperimentFetchInput(
        userId: userId ?? context?.userId,
        deviceId: deviceId ?? context?.deviceId,
        userProperties: userProperties ?? context?.userProperties);

    await _httpClient.get(input, _config?.timeout);

    _log(
        '[Experiment] Fetched ${_httpClient.fetchResult.length} experiment(s) for this user!');

    await _storeVariants();
  }

  /// Get variant assigned by flagkey
  ExperimentVariant? variant(String flagKey) {
    final variant = _getVariant(flagKey);

    if (_config?.automaticExposureTracking != null &&
        _config!.automaticExposureTracking!) {
      unawaited(exposure(flagKey));
    }

    _log('[Experiment] Variant for $flagKey is ${variant?.value}');

    return variant;
  }

  /// Track exposure event - NECESSARY `exposureTrackerProvider`
  Future<void> exposure(String flagKey) async {
    final exposureTrackerProvider = _config?.exposureTrackingProvider;
    final variant = _getVariant(flagKey);
    final instanceName = _getInstanceName();

    if (variant != null && exposureTrackerProvider != null) {
      await exposureTrackerProvider.exposure(flagKey, variant, instanceName);
    }

    _log(
        '[Experiment] Exposure event logged for $flagKey with variant: ${variant?.value}');
  }

  /// Clear SDK storage
  Future<void> clear() async {
    await _localStorage.replaceAll({});
  }

  /// Return all experiments and flags of this users
  Map<String, ExperimentVariant> all() {
    return _localStorage.getAll();
  }

  ExperimentVariant? _getVariant(String key) {
    return _localStorage.get(key);
  }

  Future<void> _storeVariants() async {
    final variants = <String, ExperimentVariant>{};
    for (final entry in _httpClient.fetchResult.entries) {
      variants[entry.key] = entry.value.toVariant();
    }
    await _localStorage.replaceAll(variants);
  }

  void _log(String message) {
    if (_config?.debug ?? false) {
      // ignore: avoid_print
      print(message);
    }
  }
}
