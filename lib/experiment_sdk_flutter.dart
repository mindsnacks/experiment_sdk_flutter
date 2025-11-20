import 'package:experiment_sdk_flutter/experiment_client.dart';
import 'package:experiment_sdk_flutter/types/experiment_config.dart';

// Experiment class is the initial main point of contact and responsible to construct ExperimentClient
class Experiment {
  /// Initialize ExperimentClient asynchronously
  static Future<ExperimentClient> initialize({
    required String apiKey,
    ExperimentConfig? config,
  }) {
    return ExperimentClient.create(apiKey: apiKey, config: config);
  }
}
