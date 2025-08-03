import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/widgets/banner_tile.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:flutter/material.dart';

class ManageBanners extends StatelessWidget {
  const ManageBanners({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.manageBanners ?? 'Manage Banners',
        ),
      ),
      body: StreamBuilder(
        stream: AppServices.getAllBannersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final banners = snapshot.data ?? [];
          return ListView.builder(
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final banner = banners[index];
              return BannerTile(banner: banner);
            },
          );
        },
      ),
    );
  }
}
