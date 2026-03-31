import 'package:flutter/material.dart';

/// Visual indicator for TLS version and cipher suite.
class TlsIndicator extends StatelessWidget {
  final String? tlsVersion;
  final String? cipher;

  const TlsIndicator({
    super.key,
    this.tlsVersion,
    this.cipher,
  });

  bool get _isSecure => tlsVersion == 'TLS 1.3';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _isSecure
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isSecure ? Icons.lock : Icons.lock_open,
            size: 18,
            color: _isSecure ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tlsVersion ?? 'Unknown',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _isSecure ? Colors.green : Colors.orange,
                ),
              ),
              if (cipher != null)
                Text(
                  cipher!,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                    fontFamily: 'monospace',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
