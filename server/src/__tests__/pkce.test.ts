import {
  generateCodeVerifier,
  generateCodeChallenge,
  verifyCodeChallenge,
  storeAuthCode,
  consumeAuthCode,
} from '../services/pkce';

describe('PKCE Verifier/Challenge', () => {
  it('should generate a verifier of valid length', () => {
    const verifier = generateCodeVerifier();
    expect(verifier.length).toBeGreaterThanOrEqual(43);
    expect(verifier.length).toBeLessThanOrEqual(128);
  });

  it('should generate unique verifiers', () => {
    const v1 = generateCodeVerifier();
    const v2 = generateCodeVerifier();
    expect(v1).not.toBe(v2);
  });

  it('should generate S256 challenge from verifier', () => {
    const verifier = generateCodeVerifier();
    const challenge = generateCodeChallenge(verifier);
    expect(challenge).toBeTruthy();
    expect(challenge).not.toBe(verifier);
  });

  it('should verify matching verifier/challenge pair', () => {
    const verifier = generateCodeVerifier();
    const challenge = generateCodeChallenge(verifier);
    expect(verifyCodeChallenge(verifier, challenge, 'S256')).toBe(true);
  });

  it('should reject mismatched verifier/challenge pair', () => {
    const verifier1 = generateCodeVerifier();
    const verifier2 = generateCodeVerifier();
    const challenge = generateCodeChallenge(verifier1);
    expect(verifyCodeChallenge(verifier2, challenge, 'S256')).toBe(false);
  });
});

describe('Authorization Code Store', () => {
  it('should store and consume auth code with valid PKCE', () => {
    const verifier = generateCodeVerifier();
    const challenge = generateCodeChallenge(verifier);
    const code = 'test-auth-code-' + Date.now();

    storeAuthCode(code, challenge, 'user123', true);
    const result = consumeAuthCode(code, verifier);

    expect(result).not.toBeNull();
    expect(result?.userId).toBe('user123');
    expect(result?.mfaVerified).toBe(true);
  });

  it('should reject auth code with wrong verifier', () => {
    const verifier = generateCodeVerifier();
    const wrongVerifier = generateCodeVerifier();
    const challenge = generateCodeChallenge(verifier);
    const code = 'test-wrong-verifier-' + Date.now();

    storeAuthCode(code, challenge, 'user123', true);
    const result = consumeAuthCode(code, wrongVerifier);

    expect(result).toBeNull();
  });

  it('should consume auth code only once (single-use)', () => {
    const verifier = generateCodeVerifier();
    const challenge = generateCodeChallenge(verifier);
    const code = 'test-single-use-' + Date.now();

    storeAuthCode(code, challenge, 'user123', true);

    const first = consumeAuthCode(code, verifier);
    expect(first).not.toBeNull();

    const second = consumeAuthCode(code, verifier);
    expect(second).toBeNull();
  });

  it('should reject non-existent auth code', () => {
    const result = consumeAuthCode('non-existent-code', 'some-verifier');
    expect(result).toBeNull();
  });
});
