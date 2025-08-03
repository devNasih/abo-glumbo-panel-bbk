import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/user.dart';
import 'package:flutter/material.dart';

class AgentTileMinimal extends StatelessWidget {
  const AgentTileMinimal({
    super.key,
    required this.user,
    required this.isVerified,
    this.onTap,
    this.onApprovalToggle,
  });

  final UserModel user;
  final bool isVerified;
  final VoidCallback? onTap;
  final VoidCallback? onApprovalToggle;

  Future<void> _showApprovalDialog(BuildContext context) async {
    final bool approve =
        !isVerified; // If currently not verified, we're approving

    final bool? result = await showDialog<bool>(
      context: context,
      builder: (context) {
        final TextTheme textTheme = Theme.of(context).textTheme;
        return AlertDialog(
          title: Text(
            (approve
                    ? AppLocalizations.of(
                        context,
                      )?.areYouSureYouWantToApproveAgent
                    : AppLocalizations.of(
                        context,
                      )?.areYouSureYouWantToDisapproveAgent) ??
                (approve
                    ? "Are you sure you want to approve this agent?"
                    : "Are you sure you want to disapprove this agent?"),
            style: textTheme.titleMedium,
          ),
          content: Text(
            "Agent: ${user.name ?? 'No Name'}\nEmail: ${user.email ?? 'No Email'}",
            style: textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: Text(AppLocalizations.of(context)?.cancel ?? "Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: Text(AppLocalizations.of(context)?.yesText ?? "Yes"),
            ),
          ],
        );
      },
    );

    // If user confirmed, execute the original callback
    if (result == true && onApprovalToggle != null) {
      onApprovalToggle!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isVerified
              ? Colors.green.withOpacity(0.1)
              : Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          isVerified ? Icons.verified_user : Icons.pending,
          color: isVerified ? Colors.green.shade800 : Colors.orange.shade800,
        ),
      ),
      title: Text(
        user.name ?? 'No Name',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            user.email ?? 'No Email',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isVerified
                  ? Colors.green.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isVerified ? 'Verified' : 'Pending',
              style: TextStyle(
                color: isVerified
                    ? Colors.green.shade800
                    : Colors.orange.shade800,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      onTap: onTap,
      trailing: IconButton(
        onPressed: () => _showApprovalDialog(context),
        icon: Icon(
          isVerified ? Icons.block : Icons.approval,
          color: isVerified
              ? Colors.red.shade600
              : Theme.of(context).primaryColor,
        ),
        tooltip: isVerified ? 'Revoke Approval' : 'Approve Agent',
      ),
      isThreeLine: true,
    );
  }
}
