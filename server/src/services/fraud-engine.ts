/**
 * Anti-Fraud Engine
 *
 * Detects anomalies by comparing WebRTC RTT measurements against
 * GPS-derived expected latency. Flags GPS spoofing, VPN/proxy usage,
 * and jitter anomalies.
 */

export interface FraudInput {
  /** Measured RTT in milliseconds from WebRTC getStats() */
  measuredRttMs: number;
  /** Jitter in milliseconds from RTCP reports */
  jitterMs: number;
  /** Caller GPS latitude */
  callerLat: number;
  /** Caller GPS longitude */
  callerLon: number;
  /** Callee GPS latitude */
  calleeLat: number;
  /** Callee GPS longitude */
  calleeLon: number;
}

export interface FraudResult {
  /** Overall fraud score 0-100 (higher = more suspicious) */
  score: number;
  /** Factor breakdown */
  factors: {
    rttAnomaly: number;
    gpsSpoof: number;
    jitterAnomaly: number;
    vpnProxy: number;
  };
  /** Human-readable flags */
  flags: string[];
}

// Speed of light through fiber optic cable (approx 200,000 km/s)
const FIBER_SPEED_KM_MS = 200;
// Processing overhead baseline (ms)
const PROCESSING_OVERHEAD_MS = 10;
// Jitter threshold (ms) - above this is suspicious
const JITTER_THRESHOLD_MS = 50;
// High jitter threshold (ms) - above this is highly suspicious
const HIGH_JITTER_THRESHOLD_MS = 100;

/**
 * Calculate great-circle distance between two GPS coordinates (Haversine formula)
 */
export function haversineDistanceKm(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number {
  const R = 6371; // Earth radius in km
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

function toRad(deg: number): number {
  return (deg * Math.PI) / 180;
}

/**
 * Estimate expected RTT based on GPS distance
 * Accounts for fiber path (1.5x straight-line), processing overhead, and round-trip
 */
export function estimateExpectedRtt(distanceKm: number): number {
  const fiberPathKm = distanceKm * 1.5; // fiber routes are ~1.5x straight-line
  const oneWayMs = fiberPathKm / FIBER_SPEED_KM_MS;
  return oneWayMs * 2 + PROCESSING_OVERHEAD_MS;
}

/**
 * Compute fraud score from WebRTC stats and GPS coordinates
 */
export function computeFraudScore(input: FraudInput): FraudResult {
  const { measuredRttMs, jitterMs, callerLat, callerLon, calleeLat, calleeLon } = input;

  const distanceKm = haversineDistanceKm(callerLat, callerLon, calleeLat, calleeLon);
  const expectedRtt = estimateExpectedRtt(distanceKm);
  const rttRatio = measuredRttMs / Math.max(expectedRtt, 1);

  const factors = {
    rttAnomaly: 0,
    gpsSpoof: 0,
    jitterAnomaly: 0,
    vpnProxy: 0,
  };
  const flags: string[] = [];

  // GPS Spoofing: measured RTT much lower than expected
  // (impossible to have lower latency than physics allows)
  if (rttRatio < 0.3 && distanceKm > 100) {
    factors.gpsSpoof = 40;
    flags.push('GPS_SPOOF_SUSPECTED: RTT impossibly low for claimed distance');
  } else if (rttRatio < 0.5 && distanceKm > 50) {
    factors.gpsSpoof = 20;
    flags.push('GPS_SPOOF_POSSIBLE: RTT unusually low for distance');
  }

  // VPN/Proxy: measured RTT much higher than expected
  // (traffic routed through additional hops)
  if (rttRatio > 5 && distanceKm < 500) {
    factors.vpnProxy = 35;
    flags.push('VPN_PROXY_DETECTED: RTT far exceeds expected for distance');
  } else if (rttRatio > 3) {
    factors.vpnProxy = 15;
    flags.push('VPN_PROXY_POSSIBLE: RTT higher than expected');
  }

  // RTT Anomaly: general deviation from expected
  const rttDeviation = Math.abs(measuredRttMs - expectedRtt);
  if (rttDeviation > 200) {
    factors.rttAnomaly = 15;
    flags.push('RTT_ANOMALY: Significant deviation from expected latency');
  } else if (rttDeviation > 100) {
    factors.rttAnomaly = 8;
  }

  // Jitter Anomaly
  if (jitterMs > HIGH_JITTER_THRESHOLD_MS) {
    factors.jitterAnomaly = 15;
    flags.push('HIGH_JITTER: Network instability or traffic manipulation');
  } else if (jitterMs > JITTER_THRESHOLD_MS) {
    factors.jitterAnomaly = 8;
    flags.push('ELEVATED_JITTER: Moderate network instability');
  }

  const score = Math.min(
    100,
    factors.rttAnomaly + factors.gpsSpoof + factors.jitterAnomaly + factors.vpnProxy
  );

  return { score, factors, flags };
}
