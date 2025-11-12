import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/agents/manage_agents.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/banners/banners.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/categories/manage_categories.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/customer_support/manage_customer_support.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/customers/manage_customers.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/faq/manage_faq.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/highlighted_services/highlighted_services.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/notification_alerts/notification_alert_sending_page.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/payouts/manage_payouts.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/services/manage_services.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/tips/tips.dart';
import 'package:flutter/material.dart';

class ManageApp extends StatefulWidget {
  const ManageApp({super.key});

  @override
  State<ManageApp> createState() => _ManageAppState();
}

class _ManageAppState extends State<ManageApp> {
  late List<_TileInfo> tiles;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    tiles = [
      _TileInfo(
        key: 'manage_users',
        labelFallback:
            AppLocalizations.of(context)?.manageCategories ??
            "Manage Categories",
        icon: Icons.category,
        onTap: () => _navigateToPage('Manage Categories'),
      ),
      _TileInfo(
        key: 'manage_services',
        labelFallback:
            AppLocalizations.of(context)?.manageServices ?? "Manage Services",
        icon: Icons.settings,
        onTap: () => _navigateToPage('Manage Services'),
      ),
      _TileInfo(
        key: 'view_logs',
        labelFallback:
            AppLocalizations.of(context)?.manageHighlightedServices ??
            "Manage Highlighted Services",
        icon: Icons.history,
        onTap: () => _navigateToPage('Manage Highlighted Services'),
      ),
      _TileInfo(
        key: 'manage_banners',
        labelFallback:
            AppLocalizations.of(context)?.manageBanners ?? "Manage Banners",
        icon: Icons.ads_click,
        onTap: () => _navigateToPage('Manage Banners'),
      ),
      _TileInfo(
        key: 'manage_agents',
        labelFallback:
            AppLocalizations.of(context)?.manageTechnicians ?? "Manage Workers",
        icon: Icons.engineering_outlined,
        onTap: () => _navigateToPage('Manage Workers'),
      ),
      _TileInfo(
        key: 'manage_customers',
        labelFallback:
            AppLocalizations.of(context)?.manageCustomers ?? "Manage Customers",
        icon: Icons.group,
        onTap: () => _navigateToPage('Manage Customers'),
      ),
      _TileInfo(
        key: 'manage_tips',
        labelFallback:
            AppLocalizations.of(context)?.manageTips ?? "Manage Tips",
        icon: Icons.lightbulb,
        onTap: () => _navigateToPage('Manage Tips'),
      ),
      _TileInfo(
        key: 'manage_payouts',
        labelFallback:
            AppLocalizations.of(context)?.managePayouts ?? "Manage Payouts",
        icon: Icons.wallet,
        onTap: () => _navigateToPage('Manage Payouts'),
      ),
      _TileInfo(
        key: 'manage_faq',
        labelFallback:
            AppLocalizations.of(context)?.manageFaqs ?? "Manage FAQs",
        icon: Icons.help,
        onTap: () => _navigateToPage('Manage FAQ'),
      ),
      _TileInfo(
        key: 'manage_customer_support',
        labelFallback:
            AppLocalizations.of(context)?.manageCustomerSupport ??
            "Manage Customer Support",
        icon: Icons.support_agent_outlined,
        onTap: () => _navigateToPage('Manage Customer Support'),
      ),
      _TileInfo(
        key: 'send_notifications',
        labelFallback: AppLocalizations.of(context)!.manageNotificationAlerts,
        icon: Icons.notifications,
        onTap: () => _navigateToPage('Manage Notification Alerts'),
      ),
    ];
  }

  void _navigateToPage(String pageName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          switch (pageName) {
            case 'Manage Categories':
              return const ManageCategories();
            case 'Manage Services':
              return const ManageServices();
            case 'Manage Highlighted Services':
              return const HighlightedServices();
            case 'Manage Banners':
              return const ManageBanners();
            case 'Manage Workers':
              return const ManageAgents();
            case 'Manage Customers':
              return const ManageCustomersPage();
            case 'Manage Tips':
              return const ManageTips();
            case 'Manage FAQ':
              return const ManageFaq();
            case 'Manage Payouts':
              return const ManagePayouts();
            case 'Manage Customer Support':
              return const ManageCustomerSupport();
            case 'Manage Notification Alerts':
              return const SendNotificationPage();
            default:
              return const Placeholder();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(AppLocalizations.of(context)?.manage ?? "Manage"),
        ),
        backgroundColor: const Color(0xFF0A2463),
        foregroundColor: Colors.white,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16.0),
        itemCount: tiles.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final tile = tiles[index];
          return _buildTile(tile);
        },
      ),
    );
  }

  Widget _buildTile(_TileInfo tile) {
    const Color primary = Color(0xFF0A2463);
    const Color secondary = Color(0xFF0081FA);

    return Card(
      elevation: 2,
      shadowColor: Colors.grey.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: tile.onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primary.withOpacity(0.1), secondary.withOpacity(0.05)],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(tile.icon, size: 24, color: primary),
        ),
        title: Text(
          tile.labelFallback,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: secondary.withOpacity(0.7),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}

class _TileInfo {
  final String key;
  final String labelFallback;
  final IconData icon;
  final VoidCallback onTap;

  _TileInfo({
    required this.key,
    required this.labelFallback,
    required this.icon,
    required this.onTap,
  });
}
