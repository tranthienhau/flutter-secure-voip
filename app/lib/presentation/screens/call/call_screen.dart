import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../../widgets/cert_status_badge.dart';
import '../../widgets/tls_indicator.dart';

class CallScreen extends ConsumerStatefulWidget {
  const CallScreen({super.key});

  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen> {
  Timer? _statsTimer;
  Duration _callDuration = Duration.zero;
  Timer? _durationTimer;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _initializeCall();
  }

  Future<void> _initializeCall() async {
    try {
      await ref.read(webRtcRepositoryProvider).initialize();
      setState(() => _isConnected = true);

      // Start collecting stats every 2 seconds
      _statsTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        ref.read(callStatsProvider.notifier).refreshStats();
      });

      // Call duration timer
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _callDuration += const Duration(seconds: 1));
      });
    } catch (e) {
      // WebRTC init may fail without actual media devices in demo
      setState(() => _isConnected = false);
    }
  }

  @override
  void dispose() {
    _statsTimer?.cancel();
    _durationTimer?.cancel();
    ref.read(webRtcRepositoryProvider).dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${d.inHours > 0 ? "${d.inHours}:" : ""}$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final callStats = ref.watch(callStatsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with back button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  const TlsIndicator(
                    tlsVersion: 'TLS 1.3',
                    cipher: 'AES_CM_128_HMAC_SHA1_80',
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Call info
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.withOpacity(0.15),
                border: Border.all(
                  color: _isConnected ? Colors.green : Colors.grey,
                  width: 2,
                ),
              ),
              child: Icon(
                _isConnected ? Icons.call : Icons.call_end,
                size: 44,
                color: _isConnected ? Colors.green : Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isConnected ? 'Secure Call Active' : 'Connecting...',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDuration(_callDuration),
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
                fontFamily: 'monospace',
              ),
            ),

            const Spacer(),

            // Security overlay
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shield, color: Colors.green, size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        'Security Overlay',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      CertStatusBadge(
                        isPinned: true,
                        fingerprint: callStats?.dtlsFingerprint,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _OverlayRow(
                    label: 'SRTP Cipher',
                    value: callStats?.srtpCipher ?? 'AES_CM_128_HMAC_SHA1_80',
                    icon: Icons.enhanced_encryption,
                  ),
                  _OverlayRow(
                    label: 'ICE State',
                    value: callStats?.iceState ?? 'checking',
                    icon: Icons.cable,
                  ),
                  _OverlayRow(
                    label: 'RTT',
                    value: '${callStats?.rttMs.toStringAsFixed(1) ?? "0.0"} ms',
                    icon: Icons.speed,
                  ),
                  _OverlayRow(
                    label: 'Jitter',
                    value: '${callStats?.jitterMs.toStringAsFixed(1) ?? "0.0"} ms',
                    icon: Icons.graphic_eq,
                  ),
                  _OverlayRow(
                    label: 'Quality',
                    value: callStats?.qualityLabel ?? 'N/A',
                    icon: Icons.signal_cellular_alt,
                  ),
                  _OverlayRow(
                    label: 'Packet Loss',
                    value: '${callStats?.packetLossPercent.toStringAsFixed(2) ?? "0.00"}%',
                    icon: Icons.warning_amber,
                    isLast: true,
                  ),
                ],
              ),
            ),

            // End call button
            Padding(
              padding: const EdgeInsets.all(24),
              child: FloatingActionButton.large(
                onPressed: () => Navigator.pop(context),
                backgroundColor: Colors.red,
                child: const Icon(Icons.call_end, size: 32),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverlayRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isLast;

  const _OverlayRow({
    required this.label,
    required this.value,
    required this.icon,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
              ),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(color: Colors.grey[800], height: 1),
      ],
    );
  }
}
