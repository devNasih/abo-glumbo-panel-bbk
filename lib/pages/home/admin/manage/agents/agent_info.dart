import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/user.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class AgentInfo extends StatelessWidget {
  final UserModel agent;
  AgentInfo({super.key, required this.agent});

  static Color primary = AppColors.primary;
  static Color secondary = AppColors.secondary;
  static Color cardBackground = AppColors.bgWhite;

  final Map<String, Map<String, String>> jobCategories = {
    'plumbing': {'en': 'Plumbing', 'ar': 'السباكة'},
    'ac': {'en': 'A/C', 'ar': 'تكييف الهواء'},
    'cleaning': {'en': 'Cleaning', 'ar': 'التنظيف'},
    'electrician': {'en': 'Electrician', 'ar': 'كهربائي'},
    'flooring': {'en': 'Flooring', 'ar': 'الأرضيات'},
    'painter': {'en': 'Painter', 'ar': 'دهان'},
    'other': {'en': 'Other', 'ar': 'أخرى'},
  };

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        throw 'Could not launch $launchUri';
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error launching phone call: $e');
      }
    }
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$label ${AppLocalizations.of(context)!.copiedToClipboard}',
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cardBackground,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuickActionsCard(context),
                  const SizedBox(height: 16),
                  _buildPersonalInfoCard(context),
                  const SizedBox(height: 16),
                  if (agent.docUrl != null && agent.docUrl!.isNotEmpty)
                    _buildIqamaCard(context),
                  if (agent.docUrl != null && agent.docUrl!.isNotEmpty)
                    const SizedBox(height: 16),
                  if (agent.certifications != null &&
                      agent.certifications!.isNotEmpty)
                    _buildCertificationsCard(context),
                  if (agent.certifications != null &&
                      agent.certifications!.isNotEmpty)
                    const SizedBox(height: 16),
                  _buildBankDetailsCard(context),
                  const SizedBox(height: 16),
                  if (agent.jobRoles != null && agent.jobRoles!.isNotEmpty)
                    _buildJobRolesCard(context),
                  if (agent.jobRoles != null && agent.jobRoles!.isNotEmpty)
                    const SizedBox(height: 16),
                  _buildSystemInfoCard(context),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIqamaCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.badge, color: Colors.blue, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.iqama,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                agent.docUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                        color: primary,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Failed to load image',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificationsCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.only(
                    left: 10,
                    right: 10,
                    top: 10,
                    bottom: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.workspace_premium,
                    color: Colors.purple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    maxLines: 2,
                    AppLocalizations.of(
                      context,
                    )!.certificationsrelevantExperienceDocuments,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                ),
              ],
            ),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: agent.certifications!.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final certUrl = agent.certifications![index];
                final fileName = _getFileNameFromUrl(certUrl);

                return InkWell(
                  onTap: () => _launchCertificationUrl(certUrl),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.purple.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.picture_as_pdf,
                            color: Colors.purple,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fileName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap to view document',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.open_in_new,
                          color: Colors.purple.withOpacity(0.6),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchCertificationUrl(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error launching certification URL: $e');
      }
    }
  }

  String _getFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      if (segments.isNotEmpty) {
        String fileName = segments.last;
        // Decode URL-encoded characters
        fileName = Uri.decodeComponent(fileName);
        // If filename is too long, truncate it
        if (fileName.length > 40) {
          final extension = fileName.split('.').last;
          fileName = '${fileName.substring(0, 35)}....$extension';
        }
        return fileName;
      }
      return 'Certification Document ${url.hashCode.abs() % 1000}';
    } catch (e) {
      return 'Certification Document';
    }
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      title: Text(AppLocalizations.of(context)!.agentInfo),
      expandedHeight: 300,
      floating: false,
      pinned: true,
      backgroundColor: primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primary, secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Hero(
                  tag: 'agent_${agent.uid}',
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 60,
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
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: primary,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  agent.name ?? 'Unknown Agent',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (agent.isVerified == true)
                      _buildBadge(
                        AppLocalizations.of(context)!.verified,
                        Icons.verified,
                        Colors.green,
                      ),
                    if (agent.isVerified == true && agent.isAdmin == true)
                      const SizedBox(width: 10),
                    if (agent.isAdmin == true)
                      _buildBadge(
                        AppLocalizations.of(context)!.admin,
                        Icons.admin_panel_settings,
                        Colors.orange,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.quickActions,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (agent.phone != null && agent.phone!.isNotEmpty)
                  _buildQuickActionButton(
                    context,
                    Icons.phone,
                    AppLocalizations.of(context)!.call,
                    Colors.green,
                    () => _makePhoneCall(agent.phone!),
                  ),
                if (agent.email != null && agent.email!.isNotEmpty)
                  _buildQuickActionButton(
                    context,
                    Icons.email,
                    AppLocalizations.of(context)!.email,
                    Colors.blue,
                    () async {
                      final Uri emailUri = Uri(
                        scheme: 'mailto',
                        path: agent.email,
                      );
                      if (await canLaunchUrl(emailUri)) {
                        await launchUrl(emailUri);
                      }
                    },
                  ),
                _buildQuickActionButton(
                  context,
                  Icons.copy,
                  AppLocalizations.of(context)!.copyId,
                  Colors.purple,
                  () => _copyToClipboard(context, agent.uid ?? '', 'User ID'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.person, color: primary, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.personalInformation,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildModernInfoRow(
              context,
              Icons.badge_outlined,
              AppLocalizations.of(context)!.name,
              agent.name,
            ),
            _buildDivider(),
            _buildModernInfoRow(
              context,
              Icons.email_outlined,
              AppLocalizations.of(context)!.email,
              agent.email,
            ),
            _buildDivider(),
            _buildModernInfoRow(
              context,
              Icons.phone_outlined,
              AppLocalizations.of(context)!.phone,
              agent.phone,
            ),
            _buildDivider(),
            _buildModernInfoRow(
              context,
              Icons.public,
              AppLocalizations.of(context)!.country,
              agent.country,
            ),
            _buildDivider(),
            _buildModernInfoRow(
              context,
              Icons.location_city_outlined,
              AppLocalizations.of(context)!.district,
              agent.districtName,
            ),
            _buildDivider(),
            _buildModernInfoRow(
              context,
              Icons.language,
              AppLocalizations.of(context)!.languageCode,
              agent.lanCode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankDetailsCard(BuildContext context) {
    // Handle null or empty payoutAccounts
    if (agent.payoutAccounts == null || agent.payoutAccounts!.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance,
                      color: Colors.grey,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context)!.bankAccountDetails,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  'No bank account details available',
                  style: TextStyle(color: Colors.grey[600], fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Try to find primary account, otherwise use the first account
    final account = agent.payoutAccounts!.firstWhere(
      (element) => element.isPrimary == true,
      orElse: () => agent.payoutAccounts!.first,
    );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [primary.withOpacity(0.05), secondary.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance,
                      color: Colors.green,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context)!.bankAccountDetails,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildBankInfoRow(
                context,
                Icons.business,
                AppLocalizations.of(context)!.bankName,
                account.bankName ?? 'Not provided',
              ),
              _buildDivider(),
              _buildBankInfoRow(
                context,
                Icons.person_outline,
                AppLocalizations.of(context)!.accountHolderName,
                account.accountHolderName ?? 'Not provided',
              ),
              _buildDivider(),
              _buildBankInfoRow(
                context,
                Icons.credit_card,
                AppLocalizations.of(context)!.accountNumber,
                account.accountNumber ?? 'Not provided',
                canCopy: true,
              ),
              _buildDivider(),
              _buildBankInfoRow(
                context,
                Icons.account_balance_wallet,
                AppLocalizations.of(context)!.iban,
                account.ifscCode ?? 'Not provided',
                canCopy: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBankInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String? value, {
    bool canCopy = false,
  }) {
    final displayValue = value ?? 'Not provided';
    final hasValue =
        value != null && value.isNotEmpty && value != 'Not provided';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayValue,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
                    color: hasValue ? Colors.black87 : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          if (canCopy && hasValue)
            IconButton(
              icon: Icon(Icons.copy, color: secondary, size: 18),
              onPressed: () => _copyToClipboard(context, displayValue, label),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildJobRolesCard(BuildContext context) {
    final currentLocale = Localizations.localeOf(context).languageCode;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.work, color: Colors.orange, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.jobRoles,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: agent.jobRoles!
                  .map(
                    (role) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [secondary.withOpacity(0.8), secondary],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: secondary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.verified_user,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getLocalizedJobCategory(role, currentLocale),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemInfoCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: Colors.grey[700],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.systemInformation,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildModernInfoRow(
              context,
              Icons.fingerprint,
              AppLocalizations.of(context)!.userId,
              agent.uid,
              trailing: IconButton(
                icon: Icon(Icons.copy, color: secondary, size: 18),
                onPressed: () =>
                    _copyToClipboard(context, agent.uid ?? '', 'User ID'),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
            _buildDivider(),
            _buildModernInfoRow(
              context,
              Icons.calendar_today,
              AppLocalizations.of(context)!.createdAt,
              _formatTimestamp(agent.createdAt),
            ),
            _buildDivider(),
            _buildModernInfoRow(
              context,
              Icons.update,
              AppLocalizations.of(context)!.updatedAt,
              _formatTimestamp(agent.updatedAt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String? value, {
    Widget? trailing,
  }) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(color: Colors.grey[300], height: 1, thickness: 1);
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
