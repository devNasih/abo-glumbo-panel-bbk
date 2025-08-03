import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/models/categories.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CategoryTileDevWidget extends StatelessWidget {
  const CategoryTileDevWidget({super.key, required this.category});
  final CategoryModel category;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      padding: const EdgeInsets.only(left: 13, right: 13, top: 13, bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: CachedNetworkImage(
              imageUrl: category.svg ?? '',
              height: 85,
              width: 85,
              fit: BoxFit.cover,
              placeholder: (context, url) => Center(
                child: Loader(size: 20, color: Colors.grey.withOpacity(0.5)),
              ),
              errorWidget: (context, url, error) =>
                  Icon(Icons.error, color: Colors.red.withOpacity(0.7)),
            ),
          ),
          const SizedBox(width: 17),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  Directionality.of(context) == TextDirection.rtl
                      ? category.name_ar ?? ""
                      : category.name ?? "",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              // context.push(AppRoutes.devEditCategory, extra: widget.category);
            },
            child: const Icon(Icons.edit),
          ),
        ],
      ),
    );
  }
}
