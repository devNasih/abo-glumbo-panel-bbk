import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/tipping.dart';
import 'package:flutter/material.dart';

class TipsTileCompact extends StatelessWidget {
  const TipsTileCompact({
    super.key,
    required this.tip,
    this.onTap,
    this.formatLastUpdated,
  });

  final TippingModel tip;
  final VoidCallback? onTap;
  final String Function(DateTime?)? formatLastUpdated;

  @override
  Widget build(BuildContext context) {
    final hasPositiveTip = tip.cashtip != null && tip.cardtip! > 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Enhanced Avatar
                _buildAvatar(hasPositiveTip),
                const SizedBox(width: 16),
                // Agent Info Section
                Expanded(child: _buildAgentInfo(context)),
                const SizedBox(width: 12),
                // Tip Amount Badge
                _buildTipBadge(hasPositiveTip, context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(bool hasPositiveTip) {
    return Stack(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: hasPositiveTip
                  ? [Colors.green.shade400, Colors.green.shade600]
                  : [Colors.blue.shade400, Colors.blue.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (hasPositiveTip ? Colors.green : Colors.blue)
                    .withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            hasPositiveTip ? Icons.account_balance_wallet : Icons.person,
            color: Colors.white,
            size: 26,
          ),
        ),
        if (tip.payoutRequested != null && tip.payoutRequested == true)
          Positioned(
            right: 0,
            top: 0,
            child: CircleAvatar(radius: 5, backgroundColor: Colors.red),
          ),
      ],
    );
  }

  Widget _buildAgentInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Agent Name
        Text(
          tip.agentName ?? "Unknown Agent",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
            letterSpacing: -0.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        // Last Updated with Icon
        Row(
          children: [
            Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                formatLastUpdated?.call(tip.lastUpdated?.toDate()) ??
                    _getDefaultFormattedDate(context),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        // Phone Number (if available)
        if (tip.agentPhone?.isNotEmpty == true) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.phone, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  tip.agentPhone!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTipBadge(bool hasPositiveTip, BuildContext context) {
    final totalTip = (tip.cashtip ?? 0.0) + (tip.cardtip ?? 0.0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: hasPositiveTip
            ? LinearGradient(
                colors: [Colors.green.shade50, Colors.green.shade100],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : LinearGradient(
                colors: [Colors.grey.shade50, Colors.grey.shade100],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasPositiveTip ? Colors.green.shade300 : Colors.grey.shade300,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (hasPositiveTip ? Colors.green : Colors.grey).withOpacity(
              0.1,
            ),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppLocalizations.of(context)!.totalTips,
            style: TextStyle(
              fontSize: 10,
              color: hasPositiveTip
                  ? Colors.green.shade600
                  : Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "${totalTip.toStringAsFixed(2)} ${AppLocalizations.of(context)!.sar}",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: hasPositiveTip
                  ? Colors.green.shade700
                  : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  String _getDefaultFormattedDate(BuildContext context) {
    if (tip.lastUpdated == null) return 'No date';

    final lastUpdatedDate = tip.lastUpdated!.toDate();
    final now = DateTime.now();
    final difference = now.difference(lastUpdatedDate);

    if (difference.inDays > 7) {
      return '${lastUpdatedDate.day}/${lastUpdatedDate.month}/${lastUpdatedDate.year}';
    } else if (difference.inDays > 0) {
      return AppLocalizations.of(context)!.daysAgo(difference.inDays);
    } else if (difference.inHours > 0) {
      return AppLocalizations.of(context)!.hoursAgo(difference.inHours);
    } else if (difference.inMinutes > 0) {
      return AppLocalizations.of(context)!.minutesAgo(difference.inMinutes);
    } else {
      return AppLocalizations.of(context)!.justNow;
    }
  }
}
