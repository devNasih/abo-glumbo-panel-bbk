import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:date_time_format/date_time_format.dart';

class TipPayoutHistoryPage extends StatefulWidget {
  const TipPayoutHistoryPage({super.key});

  @override
  State<TipPayoutHistoryPage> createState() => _TipPayoutHistoryPageState();
}

class _TipPayoutHistoryPageState extends State<TipPayoutHistoryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Map<String, String> workerNamesCache = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesSearch(Map<String, dynamic> payout, String query) {
    if (query.isEmpty) return true;

    final amount = payout['Amount'] as num?;
    final workerId = payout['workerId'] as String?;

    // Search by amount
    if (amount != null) {
      final amountStr = amount.toStringAsFixed(2);
      if (amountStr.contains(query)) return true;
    }

    // Search by technician name (from cache)
    if (workerId != null && workerNamesCache.containsKey(workerId)) {
      final workerName = workerNamesCache[workerId]!.toLowerCase();
      if (workerName.contains(query.toLowerCase())) return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.payoutHistory)),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: AppLocalizations.of(
                  context,
                )!.searchByTechnicianNameOrAmount,
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey.shade600),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // Payout List
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: AppServices.getAllTipPayoutsHistory(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: Loader(size: 32));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red.shade300,
                        ),
                        SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)!.error,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(
                            context,
                          )!.noPayoutHistoryAvailable,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final allPayouts = snapshot.data!;
                final filteredPayouts = allPayouts
                    .where((payout) => _matchesSearch(payout, _searchQuery))
                    .toList();

                if (filteredPayouts.isEmpty && _searchQuery.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No results found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Try a different search term',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: filteredPayouts.length,
                  itemBuilder: (context, index) {
                    final payout = filteredPayouts[index];
                    final amount = payout['Amount'] as num?;
                    final createdAt = payout['createdAt'] as Timestamp?;
                    final workerId = payout['workerId'] as String?;

                    return Container(
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            // Handle tap if needed
                          },
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header Row
                                Row(
                                  children: [
                                    // Icon Container
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.green.shade400,
                                            Colors.green.shade600,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.green.withOpacity(
                                              0.3,
                                            ),
                                            blurRadius: 8,
                                            offset: Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.account_balance_wallet_rounded,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    // Amount
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${AppLocalizations.of(context)!.sar} ${amount?.toStringAsFixed(2) ?? '0.00'}',
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey.shade900,
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.payoutAmount,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade500,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: 16),
                                Divider(height: 1, color: Colors.grey.shade200),
                                SizedBox(height: 16),

                                // Details Section
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Technician Info
                                          if (workerId != null)
                                            FutureBuilder(
                                              future: AppServices.getWorkerById(
                                                workerId,
                                              ),
                                              builder: (context, workerSnapshot) {
                                                final workerName =
                                                    workerSnapshot.hasData
                                                    ? workerSnapshot
                                                              .data!
                                                              .name ??
                                                          'Unknown'
                                                    : workerId;

                                                // Cache the worker name for search
                                                if (workerSnapshot.hasData &&
                                                    workerSnapshot.data!.name !=
                                                        null) {
                                                  workerNamesCache[workerId] =
                                                      workerSnapshot
                                                          .data!
                                                          .name!;
                                                }

                                                return _buildInfoRow(
                                                  context,
                                                  Icons.person_outline_rounded,
                                                  AppLocalizations.of(
                                                    context,
                                                  )!.technician,
                                                  workerName,
                                                );
                                              },
                                            ),

                                          // Date Info
                                          if (createdAt != null) ...[
                                            SizedBox(height: 12),
                                            _buildInfoRow(
                                              context,
                                              Icons.access_time_rounded,
                                              AppLocalizations.of(
                                                context,
                                              )!.date,
                                              createdAt.toDate().format(
                                                'd/m/Y - H:i A',
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: Colors.grey.shade600),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
