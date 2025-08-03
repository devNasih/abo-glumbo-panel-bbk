import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/user.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AgentInfo extends StatelessWidget {
  final UserModel agent;
  AgentInfo({super.key, required this.agent});

  static Color primary = const Color(0xFF0A2463);
  static Color secondary = const Color(0xFF0081FA);

  final Map<String, Map<String, String>> jobCategories = {
    'plumbing': {'en': 'Plumbing', 'ar': 'السباكة'},
    'ac': {'en': 'A/C', 'ar': 'تكييف الهواء'},
    'cleaning': {'en': 'Cleaning', 'ar': 'التنظيف'},
    'electrician': {'en': 'Electrician', 'ar': 'كهربائي'},
    'flooring': {'en': 'Flooring', 'ar': 'الأرضيات'},
    'painter': {'en': 'Painter', 'ar': 'دهان'},
    'other': {'en': 'Other', 'ar': 'أخرى'},
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(agent.name ?? 'Agent Details'),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(context),
            const SizedBox(height: 24),
            _buildSectionCard(
              AppLocalizations.of(context)!.personalInformation,
              Icons.person,
              [
                _buildInfoRow(
                  AppLocalizations.of(context)!.name,
                  agent.name,
                  context,
                ),
                _buildInfoRow(
                  AppLocalizations.of(context)!.email,
                  agent.email,
                  context,
                ),
                _buildInfoRow(
                  AppLocalizations.of(context)!.phone,
                  agent.phone,
                  context,
                ),
                _buildInfoRow(
                  AppLocalizations.of(context)!.country,
                  agent.country,
                  context,
                ),
                _buildInfoRow(
                  AppLocalizations.of(context)!.district,
                  agent.districtName,
                  context,
                ),
                _buildInfoRow(
                  AppLocalizations.of(context)!.languageCode,
                  agent.lanCode,
                  context,
                ),
              ],
            ),

            const SizedBox(height: 16),

            _buildSectionCard(
              AppLocalizations.of(context)!.accountStatus,
              Icons.verified_user,
              [
                _buildStatusRow(
                  AppLocalizations.of(context)!.adminStatus,
                  agent.isAdmin ?? false,
                  context,
                ),
                _buildStatusRow(
                  AppLocalizations.of(context)!.verified,
                  agent.isVerified ?? false,
                  context,
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (agent.jobRoles != null && agent.jobRoles!.isNotEmpty)
              _buildSectionCard(
                AppLocalizations.of(context)!.jobRoles,
                Icons.work,
                [_buildJobRoles(context)],
              ),

            const SizedBox(height: 16),

            _buildSectionCard(
              AppLocalizations.of(context)!.systemInformation,
              Icons.info,
              [
                _buildInfoRow(
                  AppLocalizations.of(context)!.userId,
                  agent.uid,
                  context,
                ),
                _buildInfoRow(
                  AppLocalizations.of(context)!.createdAt,
                  _formatTimestamp(agent.createdAt),
                  context,
                ),
                _buildInfoRow(
                  AppLocalizations.of(context)!.updatedAt,
                  _formatTimestamp(agent.updatedAt),
                  context,
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            backgroundImage: agent.profileUrl != null
                ? NetworkImage(agent.profileUrl!)
                : null,
            child: agent.profileUrl == null
                ? Text(
                    agent.name?.isNotEmpty == true
                        ? agent.name![0].toUpperCase()
                        : 'A',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  agent.name ?? 'Unknown Agent',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  agent.email ?? 'No email',
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (agent.isAdmin == true)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.admin,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (agent.isAdmin == true) const SizedBox(width: 8),
                    if (agent.isVerified == true)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.verified,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: primary, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value, BuildContext context) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, bool status, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: status ? Colors.green.shade100 : Colors.red.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: status ? Colors.green : Colors.red,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  status ? Icons.check_circle : Icons.cancel,
                  color: status ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  status
                      ? AppLocalizations.of(context)!.yes
                      : AppLocalizations.of(context)!.no,
                  style: TextStyle(
                    color: status ? Colors.green.shade800 : Colors.red.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobRoles(BuildContext context) {
    final currentLocale = Localizations.localeOf(context).languageCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.assignedRoles,
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: agent.jobRoles!
              .map(
                (role) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: secondary.withOpacity(0.3)),
                  ),
                  child: Text(
                    _getLocalizedJobCategory(role, currentLocale),
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  String? _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return null;
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getLocalizedJobCategory(String jobKey, String locale) {
    if (jobCategories.containsKey(jobKey.toLowerCase())) {
      return jobCategories[jobKey.toLowerCase()]![locale] ?? jobKey;
    }

    return jobKey;
  }
}
