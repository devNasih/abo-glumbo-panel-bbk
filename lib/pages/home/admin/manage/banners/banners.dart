import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/banner.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/banners/add_banner.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/bloc/manage_app_bloc.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/widgets/banner_tile.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ManageBanners extends StatelessWidget {
  const ManageBanners({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<ManageAppBloc, ManageAppState>(
      listener: (context, state) {
        if (state is BannerDeleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)?.bannerDeleted ??
                    'Banner deleted successfully',
              ),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      child: Scaffold(
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
                return BannerTile(
                  banner: banner,
                  onEdit: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddBanner(banner: banner),
                    ),
                  ),
                  onDelete: () =>
                      _showDeleteConfirmationDialog(context, banner),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddBanner()),
          ),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, BannerModel banner) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Banner'),
          content: const Text(
            'Are you sure you want to delete this banner? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<ManageAppBloc>().add(
                  DeleteBannerEvent(banner.id ?? ''),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
