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
          color: isVerified 
            ? Colors.green.shade800 
            : Colors.orange.shade800,
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
        onPressed: onApprovalToggle,
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
