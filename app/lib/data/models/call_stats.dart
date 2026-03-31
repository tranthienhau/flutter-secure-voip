class CallStats {
  final double rttMs;
  final double jitterMs;
  final String? tlsVersion;
  final String? srtpCipher;
  final String? dtlsFingerprint;
  final String? iceState;
  final String? candidateType;
  final int packetsReceived;
  final int packetsSent;
  final int packetsLost;

  const CallStats({
    required this.rttMs,
    required this.jitterMs,
    this.tlsVersion,
    this.srtpCipher,
    this.dtlsFingerprint,
    this.iceState,
    this.candidateType,
    this.packetsReceived = 0,
    this.packetsSent = 0,
    this.packetsLost = 0,
  });

  double get packetLossPercent {
    if (packetsReceived + packetsLost == 0) return 0;
    return (packetsLost / (packetsReceived + packetsLost)) * 100;
  }

  String get qualityLabel {
    if (rttMs < 50 && jitterMs < 20) return 'Excellent';
    if (rttMs < 150 && jitterMs < 50) return 'Good';
    if (rttMs < 300 && jitterMs < 100) return 'Fair';
    return 'Poor';
  }
}
