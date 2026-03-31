import {
  computeFraudScore,
  haversineDistanceKm,
  estimateExpectedRtt,
  FraudInput,
} from '../services/fraud-engine';

describe('Haversine Distance', () => {
  it('should calculate distance between NYC and London correctly', () => {
    // NYC: 40.7128, -74.0060 | London: 51.5074, -0.1278
    const distance = haversineDistanceKm(40.7128, -74.006, 51.5074, -0.1278);
    expect(distance).toBeGreaterThan(5500);
    expect(distance).toBeLessThan(5700);
  });

  it('should return 0 for same coordinates', () => {
    const distance = haversineDistanceKm(0, 0, 0, 0);
    expect(distance).toBe(0);
  });

  it('should handle antipodal points', () => {
    const distance = haversineDistanceKm(0, 0, 0, 180);
    expect(distance).toBeGreaterThan(20000);
    expect(distance).toBeLessThan(20100);
  });
});

describe('Expected RTT Estimation', () => {
  it('should return processing overhead for zero distance', () => {
    const rtt = estimateExpectedRtt(0);
    expect(rtt).toBe(10); // PROCESSING_OVERHEAD_MS
  });

  it('should increase with distance', () => {
    const short = estimateExpectedRtt(100);
    const long = estimateExpectedRtt(10000);
    expect(long).toBeGreaterThan(short);
  });
});

describe('Fraud Score Computation', () => {
  it('should return low score for normal traffic (same city)', () => {
    const input: FraudInput = {
      measuredRttMs: 15,
      jitterMs: 5,
      callerLat: 40.7128,
      callerLon: -74.006,
      calleeLat: 40.73,
      calleeLon: -73.99,
    };
    const result = computeFraudScore(input);
    expect(result.score).toBeLessThan(20);
    expect(result.flags.length).toBe(0);
  });

  it('should detect GPS spoofing (RTT too low for distance)', () => {
    // Claiming to be in Tokyo but RTT suggests nearby
    const input: FraudInput = {
      measuredRttMs: 5,
      jitterMs: 2,
      callerLat: 40.7128,
      callerLon: -74.006,
      calleeLat: 35.6762,
      calleeLon: 139.6503,
    };
    const result = computeFraudScore(input);
    expect(result.score).toBeGreaterThan(30);
    expect(result.factors.gpsSpoof).toBeGreaterThan(0);
    expect(result.flags.some((f) => f.includes('GPS_SPOOF'))).toBe(true);
  });

  it('should detect VPN/proxy (RTT too high for distance)', () => {
    // Same city but RTT suggests routing through distant proxy
    const input: FraudInput = {
      measuredRttMs: 500,
      jitterMs: 10,
      callerLat: 40.7128,
      callerLon: -74.006,
      calleeLat: 40.73,
      calleeLon: -73.99,
    };
    const result = computeFraudScore(input);
    expect(result.score).toBeGreaterThan(20);
    expect(result.factors.vpnProxy).toBeGreaterThan(0);
    expect(result.flags.some((f) => f.includes('VPN_PROXY'))).toBe(true);
  });

  it('should flag high jitter', () => {
    const input: FraudInput = {
      measuredRttMs: 50,
      jitterMs: 120,
      callerLat: 40.7128,
      callerLon: -74.006,
      calleeLat: 51.5074,
      calleeLon: -0.1278,
    };
    const result = computeFraudScore(input);
    expect(result.factors.jitterAnomaly).toBeGreaterThan(0);
    expect(result.flags.some((f) => f.includes('JITTER'))).toBe(true);
  });

  it('should cap score at 100', () => {
    // Extreme anomaly on all factors
    const input: FraudInput = {
      measuredRttMs: 2,
      jitterMs: 200,
      callerLat: 40.7128,
      callerLon: -74.006,
      calleeLat: -33.8688,
      calleeLon: 151.2093,
    };
    const result = computeFraudScore(input);
    expect(result.score).toBeLessThanOrEqual(100);
  });
});
