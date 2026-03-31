import 'package:flutter/material.dart';

/// Badge showing certificate pinning status.
class CertStatusBadge extends StatelessWidget {
  final bool isPinned;
  final String? fingerprint;

  const CertStatusBadge({
    super.key,
    required this.isPinned,
    this.fingerprint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPinned
            ? Colors.green.withOpacity(0.15)
            : Colors.red.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPinned ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPinned ? Icons.verified_user : Icons.gpp_bad,
            size: 16,
            color: isPinned ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isPinned ? 'Cert Pinned' : 'Cert Not Pinned',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isPinned ? Colors.green : Colors.red,
                ),
              ),
              if (fingerprint != null)
                Text(
                  fingerprint!.length > 16
                      ? '${fingerprint!.substring(0, 16)}...'
                      : fingerprint!,
                  style: TextStyle(
                    fontSize: 9,
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
