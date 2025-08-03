import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/highlighted_services.dart';
import 'package:aboglumbo_bbk_panel/models/service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HighlightedServiceWidget extends StatelessWidget {
  const HighlightedServiceWidget({
    super.key,
    required this.data,
  });
  final HighlightedServicesModel data;

  @override
  Widget build(BuildContext context) {
    final currentLanguage = AppLocalizations.of(context)?.localeName ?? 'en';
    final isRtlLanguage = currentLanguage == 'ar';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 10, right: 16),
          child: Text(
            data.titleLocalized(languageCode: currentLanguage) ?? '',
            style: GoogleFonts.dmSans(
              fontWeight: FontWeight.w500,
              fontSize: 16,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 13),
        SizedBox(
          height: 127,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: data.services?.length ?? 0,
            itemBuilder: (context, index) {
              return FutureBuilder(
                future: AppFirestore.servicesCollectionRef
                    .doc(data.services![index])
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingContainer(isRtlLanguage);
                  }
                  if (snapshot.hasError) {
                    return _buildErrorContainer(context, isRtlLanguage);
                  }
                  
                  final service = ServiceModel.fromDocumentSnapshot(
                      snapshot.data as DocumentSnapshot);

                  return GestureDetector(
                    onTap: () {},
                    child: Container(
                      height: 127,
                      width: 127,
                      margin: isRtlLanguage
                          ? const EdgeInsets.only(left: 13)
                          : const EdgeInsets.only(right: 13),
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          SizedBox(
                            height: 127,
                            width: 127,
                            child: _buildServiceImage(service),
                          ),
                          Container(
                            height: 88,
                            width: 127,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                stops: [0, 1],
                                begin: Alignment.center,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black,
                                ],
                              ),
                            ),
                            alignment: Directionality.of(context) ==
                                    TextDirection.ltr
                                ? Alignment.bottomLeft
                                : Alignment.bottomRight,
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              Directionality.of(context) == TextDirection.ltr
                                  ? service.name ?? ""
                                  : service.name_ar ?? "",
                              style: GoogleFonts.dmSans(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  // Helper method to build loading container
  Widget _buildLoadingContainer(bool isRtlLanguage) {
    return Container(
      height: 127,
      width: 127,
      alignment: Alignment.center,
      margin: isRtlLanguage
          ? const EdgeInsets.only(left: 13)
          : const EdgeInsets.only(right: 13),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: const CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
      ),
    );
  }

  // Helper method to build error container
  Widget _buildErrorContainer(BuildContext context, bool isRtlLanguage) {
    return Container(
      height: 127,
      width: 127,
      alignment: Alignment.center,
      margin: isRtlLanguage
          ? const EdgeInsets.only(left: 13)
          : const EdgeInsets.only(right: 13),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context)?.failedToLoadServices ?? 'Error',
            style: GoogleFonts.dmSans(
              fontSize: 10,
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Helper method to build service image with URL validation
  Widget _buildServiceImage(ServiceModel service) {
    final imageUrl = service.image?.trim() ?? '';
    
    // Check if URL is empty or invalid
    if (imageUrl.isEmpty || !_isValidUrl(imageUrl)) {
      return Container(
        color: Colors.grey[300],
        child: const Icon(
          Icons.image_not_supported,
          size: 40,
          color: Colors.grey,
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey[100],
        child:  Center(
          child: Loader(size: 20),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[300],
        child: const Icon(
          Icons.broken_image,
          size: 40,
          color: Colors.grey,
        ),
      ),
    );
  }

  // Helper method to validate URL
  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && 
             (uri.scheme == 'http' || uri.scheme == 'https') && 
             uri.host.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}