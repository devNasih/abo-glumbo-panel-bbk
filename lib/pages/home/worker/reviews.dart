import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/booking.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

class WorkerReviewsPage extends StatefulWidget {
  final String workerId;

  const WorkerReviewsPage({super.key, required this.workerId});

  @override
  State<WorkerReviewsPage> createState() => _WorkerReviewsPageState();
}

class _WorkerReviewsPageState extends State<WorkerReviewsPage> {
  List<BookingModel> reviewedBookings = [];
  bool isLoading = true;
  double averageRating = 0.0;
  Map<int, int> ratingDistribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => isLoading = true);

    try {
      // Query bookings where review field exists and agent.uid matches workerId
      final querySnapshot = await AppFirestore.bookingsCollectionRef
          .where('agent.uid', isEqualTo: widget.workerId)
          .where('bookingStatusCode', isEqualTo: 'C') // Completed bookings only
          .orderBy('completedAt', descending: true)
          .get();

      // Filter bookings that have reviews (review field is not null)
      reviewedBookings = querySnapshot.docs
          .map((doc) => BookingModel.fromQueryDocumentSnapshot(doc))
          .where((booking) => booking.review != null)
          .toList();

      _calculateStatistics();
    } catch (e) {
      debugPrint('Error loading reviews: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.errorLoadingReviews}: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _calculateStatistics() {
    if (reviewedBookings.isEmpty) return;

    // Reset distribution
    ratingDistribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

    // Calculate average and distribution
    double totalRating = 0;
    int validReviewCount = 0;

    for (var booking in reviewedBookings) {
      if (booking.review != null) {
        int rating = booking.review!.rating;
        if (rating > 0 && rating <= 5) {
          totalRating += rating;
          validReviewCount++;
          ratingDistribution[rating] = (ratingDistribution[rating] ?? 0) + 1;
        }
      }
    }

    // Calculate average out of 5 (not out of total possible points)
    averageRating = validReviewCount > 0 ? totalRating / validReviewCount : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.reviews),
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? Center(child: Loader(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadReviews,
              child: reviewedBookings.isEmpty
                  ? _buildEmptyState()
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildOverviewCard(),
                          const SizedBox(height: 16),
                          _buildRatingDistribution(),
                          const SizedBox(height: 24),
                          _buildReviewsList(),
                        ],
                      ),
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rate_review_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.noReviewsYet,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(
              context,
            )!.reviewsWillAppearHereAfterCustomersRateYourService,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber[700]!, Colors.amber[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '/ 5',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _buildStarRating(averageRating, size: 28, color: Colors.white),
          const SizedBox(height: 12),
          Text(
            '${reviewedBookings.length} ${reviewedBookings.length == 1 ? AppLocalizations.of(context)!.review : AppLocalizations.of(context)!.reviews}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingDistribution() {
    final totalReviews = reviewedBookings.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.ratingDistribution,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(5, (index) {
            int starCount = 5 - index;
            int count = ratingDistribution[starCount] ?? 0;
            double percentage = totalReviews > 0 ? count / totalReviews : 0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Text(
                    '$starCount',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.amber[600]!,
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 30,
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildReviewsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.allReviews,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ...reviewedBookings.map((booking) => _buildReviewCard(booking)),
      ],
    );
  }

  Widget _buildReviewCard(BookingModel booking) {
    final review = booking.review!;
    final customer = booking.customer;
    final rating = review.rating;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withOpacity(0.1),

                child: Text(
                  customer.name?[0].toUpperCase() ?? '',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name ?? "",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      review.createdAt != null
                          ? DateFormat(
                              'MMM dd, yyyy',
                            ).format(review.createdAt!.toDate())
                          : 'Recent',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              _buildStarRating(rating.toDouble(), size: 18),
            ],
          ),
          if (review.review.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review.review,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
          ],
          // if (review.tipAmount != null && review.tipAmount! > 0) ...[
          //   const SizedBox(height: 12),
          //   Container(
          //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          //     decoration: BoxDecoration(
          //       color: Colors.green[50],
          //       borderRadius: BorderRadius.circular(8),
          //       border: Border.all(color: Colors.green[200]!),
          //     ),
          //     child: Row(
          //       mainAxisSize: MainAxisSize.min,
          //       children: [
          //         Icon(Icons.star, size: 16, color: Colors.green[700]),
          //         const SizedBox(width: 6),
          //         Text(
          //           'Tip: ₹${review.tipAmount!.toStringAsFixed(2)}',
          //           style: TextStyle(
          //             fontSize: 13,
          //             fontWeight: FontWeight.w600,
          //             color: Colors.green[700],
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          // ],
          const SizedBox(height: 8),
          Divider(height: 1, color: Colors.grey[200]),
          const SizedBox(height: 8),
          Text(
            '${AppLocalizations.of(context)!.service}: ${Directionality.of(context) == TextDirection.ltr ? '${booking.service.name}' : booking.service.name_ar}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarRating(double rating, {double size = 20, Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return Icon(
            Icons.star,
            size: size,
            color: color ?? Colors.amber[600],
          );
        } else if (index < rating && rating % 1 != 0) {
          return Icon(
            Icons.star_half,
            size: size,
            color: color ?? Colors.amber[600],
          );
        } else {
          return Icon(
            Icons.star_border,
            size: size,
            color: color ?? Colors.grey[400],
          );
        }
      }),
    );
  }
}
