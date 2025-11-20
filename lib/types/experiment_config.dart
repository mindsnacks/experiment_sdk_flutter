import 'package:experiment_sdk_flutter/types/experiment_exposure_tracking_provider.dart';

class ExperimentConfig {
  final bool? debug;
  final String? instanceName;
  final int? fetchTimeoutMillis;
  final bool? retryFetchOnFailure;
  final bool? automaticExposureTracking;
  final ExperimentExposureTrackingProvider? exposureTrackingProvider;

  Duration get timeout => Duration(milliseconds: fetchTimeoutMillis ?? 5000);

  ExperimentConfig(
      {this.debug = false,
      this.instanceName = '\$default_instance',
      this.fetchTimeoutMillis,
      this.retryFetchOnFailure,
      this.automaticExposureTracking = false,
      this.exposureTrackingProvider});

  ExperimentConfig copyWith(
      {bool? debug,
      String? instanceName,
      int? fetchTimeoutMillis,
      bool? retryFetchOnFailure,
      bool? automaticExposureTracking,
      ExperimentExposureTrackingProvider? exposureTrackingProvider}) {
    return ExperimentConfig(
        debug: debug ?? this.debug,
        instanceName: instanceName ?? this.instanceName,
        fetchTimeoutMillis: fetchTimeoutMillis ?? this.fetchTimeoutMillis,
        retryFetchOnFailure: retryFetchOnFailure ?? this.retryFetchOnFailure,
        automaticExposureTracking:
            automaticExposureTracking ?? this.automaticExposureTracking,
        exposureTrackingProvider:
            exposureTrackingProvider ?? this.exposureTrackingProvider);
  }
}
