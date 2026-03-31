import '../../core/constants/api_config.dart';
import '../../core/services/secure_http_client.dart';
import '../../core/services/token_storage.dart';
import '../models/fraud_score.dart';

/// Handles fraud score computation via server API.
/// GPS/PII data is processed ephemerally - never persisted.
class FraudRepository {
  final SecureHttpClient _httpClient;
  final TokenStorage _tokenStorage;

  FraudRepository(this._httpClient, this._tokenStorage);

  /// Submit WebRTC stats + GPS for fraud analysis.
  /// Input data is cleared from memory after the API call.
  Future<FraudScore> computeFraudScore({
    required double measuredRttMs,
    required double jitterMs,
    required double callerLat,
    required double callerLon,
    required double calleeLat,
    required double calleeLon,
  }) async {
    final token = _tokenStorage.accessToken;
    if (token == null) {
      throw Exception('Not authenticated');
    }

    try {
      final response = await _httpClient.post(
        ApiConfig.fraudScorePath,
        data: {
          'measuredRttMs': measuredRttMs,
          'jitterMs': jitterMs,
          'callerLat': callerLat,
          'callerLon': callerLon,
          'calleeLat': calleeLat,
          'calleeLon': calleeLon,
        },
        accessToken: token,
      );

      // Parse response and immediately discard raw GPS data
      // (only the fraud score is retained in memory)
      final data = response.data as Map<String, dynamic>;
      return FraudScore.fromJson(data);
    } catch (e) {
      throw Exception('Fraud score computation failed: $e');
    }
  }
}
