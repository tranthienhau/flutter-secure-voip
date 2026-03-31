class FraudScore {
  final int score;
  final FraudFactors factors;
  final List<String> flags;
  final DateTime timestamp;

  const FraudScore({
    required this.score,
    required this.factors,
    required this.flags,
    required this.timestamp,
  });

  factory FraudScore.fromJson(Map<String, dynamic> json) {
    return FraudScore(
      score: json['score'] as int,
      factors: FraudFactors.fromJson(json['factors'] as Map<String, dynamic>),
      flags: (json['flags'] as List).cast<String>(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  String get riskLevel {
    if (score < 25) return 'Low';
    if (score < 50) return 'Medium';
    if (score < 75) return 'High';
    return 'Critical';
  }
}

class FraudFactors {
  final int rttAnomaly;
  final int gpsSpoof;
  final int jitterAnomaly;
  final int vpnProxy;

  const FraudFactors({
    required this.rttAnomaly,
    required this.gpsSpoof,
    required this.jitterAnomaly,
    required this.vpnProxy,
  });

  factory FraudFactors.fromJson(Map<String, dynamic> json) {
    return FraudFactors(
      rttAnomaly: json['rttAnomaly'] as int,
      gpsSpoof: json['gpsSpoof'] as int,
      jitterAnomaly: json['jitterAnomaly'] as int,
      vpnProxy: json['vpnProxy'] as int,
    );
  }
}
