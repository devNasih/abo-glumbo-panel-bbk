import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/widgets/highlighted_service.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:flutter/material.dart';

class HighlightedServices extends StatelessWidget {
  const HighlightedServices({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.highlightedServices ??
              'Highlighted Services',
        ),
      ),
      body: StreamBuilder(
        stream: AppServices.getAllHighlightedServicesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: Loader(size: 50));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final highlightedServices = snapshot.data ?? [];
          return ListView.builder(
            itemCount: highlightedServices.length,
            itemBuilder: (context, index) {
              final service = highlightedServices[index];
              return Stack(
                children: [
                  HighlightedServiceWidget(data: service),
                  Align(
                    alignment: Directionality.of(context) == TextDirection.ltr
                        ? Alignment.topRight
                        : Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        // context.push(
                        //   AppRoutes.devEditHighlightedServices,
                        //   extra: thisData,
                        // );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
