import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/services/unified_payout_services.dart';
import 'package:flutter/foundation.dart';

/// Migration Script for Unified Payout System
///
/// This script helps migrate from the old payout system to the new unified system.
/// Run this once to migrate all existing worker data.
class UnifiedPayoutMigration {
  /// Migrate all workers to unified wallet system
  static Future<Map<String, dynamic>> migrateAllWorkers() async {
    int successCount = 0;
    int failureCount = 0;
    List<String> failedWorkers = [];
    List<String> successfulWorkers = [];

    try {
      if (kDebugMode) {
        print('🚀 Starting migration to unified payout system...');
      }

      // Get all workers
      final workers = await AppServices.getAllAgentsStream().first;

      if (kDebugMode) {
        print('📊 Found ${workers.length} workers to migrate');
      }

      for (var worker in workers) {
        try {
          if (kDebugMode) {
            print('\n👤 Migrating worker: ${worker.name} (${worker.uid})');
          }

          // Sync existing data to unified wallet
          await UnifiedPayoutServices.syncExistingDataToUnifiedWallet(
            worker.uid!,
          );

          successCount++;
          successfulWorkers.add(worker.name ?? worker.uid ?? 'Unknown');

          if (kDebugMode) {
            print('✅ Successfully migrated ${worker.name}');
          }
        } catch (e) {
          failureCount++;
          failedWorkers.add(worker.name ?? worker.uid ?? 'Unknown');

          if (kDebugMode) {
            print('❌ Failed to migrate ${worker.name}: $e');
          }
        }
      }

      if (kDebugMode) {
        print('\n' + '=' * 50);
        print('📈 Migration Summary:');
        print('   Total Workers: ${workers.length}');
        print('   ✅ Successful: $successCount');
        print('   ❌ Failed: $failureCount');
        print('=' * 50);

        if (successfulWorkers.isNotEmpty) {
          print('\n✅ Successfully Migrated:');
          for (var name in successfulWorkers) {
            print('   - $name');
          }
        }

        if (failedWorkers.isNotEmpty) {
          print('\n❌ Failed Migrations:');
          for (var name in failedWorkers) {
            print('   - $name');
          }
        }
      }

      return {
        'success': true,
        'totalWorkers': workers.length,
        'successCount': successCount,
        'failureCount': failureCount,
        'successfulWorkers': successfulWorkers,
        'failedWorkers': failedWorkers,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Migration failed: $e');
      }

      return {
        'success': false,
        'error': e.toString(),
        'successCount': successCount,
        'failureCount': failureCount,
        'successfulWorkers': successfulWorkers,
        'failedWorkers': failedWorkers,
      };
    }
  }

  /// Migrate a single worker
  static Future<bool> migrateSingleWorker(String workerId) async {
    try {
      if (kDebugMode) {
        print('🚀 Migrating worker: $workerId');
      }

      await UnifiedPayoutServices.syncExistingDataToUnifiedWallet(workerId);

      if (kDebugMode) {
        print('✅ Successfully migrated worker: $workerId');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to migrate worker $workerId: $e');
      }
      return false;
    }
  }

  /// Verify migration for a worker
  static Future<Map<String, dynamic>> verifyWorkerMigration(
    String workerId,
  ) async {
    try {
      if (kDebugMode) {
        print('🔍 Verifying migration for worker: $workerId');
      }

      // Get old system data
      final transactions = await AppServices.getWorkerTransactions(workerId);
      final tippingData = await AppServices.getWorkerTippingData(workerId);
      final bonusAmount = await AppServices.getWorkerBonusAmounts(workerId);
      final paidAmounts = await AppServices.getWorkerPaidAmounts(workerId);

      // Calculate expected values
      double expectedTotalEarnings = 0.0;
      for (var transaction in transactions) {
        if (transaction.paymentStatus.toLowerCase() == 'completed' ||
            transaction.paymentStatus.toLowerCase() == 'paid') {
          if (transaction.paymentMethod.toLowerCase() == 'cards') {
            expectedTotalEarnings += transaction.amount;
          }
        }
      }

      final expectedAvailableEarnings = expectedTotalEarnings - paidAmounts;
      final expectedCardTips = tippingData.cardtip ?? 0.0;
      final expectedCashTips = tippingData.cashtip ?? 0.0;
      final expectedTotalTips = expectedCardTips + expectedCashTips;
      final expectedAvailableBonus = bonusAmount;

      // Get unified wallet data
      final wallet = await UnifiedPayoutServices.getUnifiedWallet(workerId);

      // Compare values
      final earningsMatch =
          (wallet.totalEarnings ?? 0.0) == expectedTotalEarnings;
      final availableEarningsMatch =
          (wallet.availableEarnings ?? 0.0) == expectedAvailableEarnings;
      final cardTipsMatch = (wallet.cardTips ?? 0.0) == expectedCardTips;
      final cashTipsMatch = (wallet.cashTips ?? 0.0) == expectedCashTips;
      final totalTipsMatch = (wallet.totalTips ?? 0.0) == expectedTotalTips;
      final bonusMatch =
          (wallet.availableBonus ?? 0.0) == expectedAvailableBonus;

      final allMatch =
          earningsMatch &&
          availableEarningsMatch &&
          cardTipsMatch &&
          cashTipsMatch &&
          totalTipsMatch &&
          bonusMatch;

      if (kDebugMode) {
        print('\n📊 Verification Results:');
        print(
          '   Earnings: ${earningsMatch ? '✅' : '❌'} (Expected: $expectedTotalEarnings, Got: ${wallet.totalEarnings})',
        );
        print(
          '   Available Earnings: ${availableEarningsMatch ? '✅' : '❌'} (Expected: $expectedAvailableEarnings, Got: ${wallet.availableEarnings})',
        );
        print(
          '   Card Tips: ${cardTipsMatch ? '✅' : '❌'} (Expected: $expectedCardTips, Got: ${wallet.cardTips})',
        );
        print(
          '   Cash Tips: ${cashTipsMatch ? '✅' : '❌'} (Expected: $expectedCashTips, Got: ${wallet.cashTips})',
        );
        print(
          '   Total Tips: ${totalTipsMatch ? '✅' : '❌'} (Expected: $expectedTotalTips, Got: ${wallet.totalTips})',
        );
        print(
          '   Bonus: ${bonusMatch ? '✅' : '❌'} (Expected: $expectedAvailableBonus, Got: ${wallet.availableBonus})',
        );
        print('   Overall: ${allMatch ? '✅ PASSED' : '❌ FAILED'}');
      }

      return {
        'success': allMatch,
        'workerId': workerId,
        'checks': {
          'earnings': earningsMatch,
          'availableEarnings': availableEarningsMatch,
          'cardTips': cardTipsMatch,
          'cashTips': cashTipsMatch,
          'totalTips': totalTipsMatch,
          'bonus': bonusMatch,
        },
        'expected': {
          'totalEarnings': expectedTotalEarnings,
          'availableEarnings': expectedAvailableEarnings,
          'cardTips': expectedCardTips,
          'cashTips': expectedCashTips,
          'totalTips': expectedTotalTips,
          'bonus': expectedAvailableBonus,
        },
        'actual': {
          'totalEarnings': wallet.totalEarnings,
          'availableEarnings': wallet.availableEarnings,
          'cardTips': wallet.cardTips,
          'cashTips': wallet.cashTips,
          'totalTips': wallet.totalTips,
          'bonus': wallet.availableBonus,
        },
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Verification failed: $e');
      }

      return {'success': false, 'error': e.toString()};
    }
  }

  /// Verify all workers
  static Future<Map<String, dynamic>> verifyAllWorkers() async {
    int passedCount = 0;
    int failedCount = 0;
    List<String> passedWorkers = [];
    List<String> failedWorkers = [];

    try {
      if (kDebugMode) {
        print('🔍 Starting verification of all workers...');
      }

      final workers = await AppServices.getAllAgentsStream().first;

      if (kDebugMode) {
        print('📊 Found ${workers.length} workers to verify');
      }

      for (var worker in workers) {
        try {
          final result = await verifyWorkerMigration(worker.uid!);

          if (result['success'] == true) {
            passedCount++;
            passedWorkers.add(worker.name ?? worker.uid ?? 'Unknown');
          } else {
            failedCount++;
            failedWorkers.add(worker.name ?? worker.uid ?? 'Unknown');
          }
        } catch (e) {
          failedCount++;
          failedWorkers.add(worker.name ?? worker.uid ?? 'Unknown');

          if (kDebugMode) {
            print('❌ Verification failed for ${worker.name}: $e');
          }
        }
      }

      if (kDebugMode) {
        print('\n' + '=' * 50);
        print('📈 Verification Summary:');
        print('   Total Workers: ${workers.length}');
        print('   ✅ Passed: $passedCount');
        print('   ❌ Failed: $failedCount');
        print('=' * 50);

        if (passedWorkers.isNotEmpty) {
          print('\n✅ Passed Verification:');
          for (var name in passedWorkers) {
            print('   - $name');
          }
        }

        if (failedWorkers.isNotEmpty) {
          print('\n❌ Failed Verification:');
          for (var name in failedWorkers) {
            print('   - $name');
          }
        }
      }

      return {
        'success': failedCount == 0,
        'totalWorkers': workers.length,
        'passedCount': passedCount,
        'failedCount': failedCount,
        'passedWorkers': passedWorkers,
        'failedWorkers': failedWorkers,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Verification failed: $e');
      }

      return {
        'success': false,
        'error': e.toString(),
        'passedCount': passedCount,
        'failedCount': failedCount,
      };
    }
  }

  /// Generate migration report
  static Future<String> generateMigrationReport() async {
    final buffer = StringBuffer();

    buffer.writeln('=' * 60);
    buffer.writeln('UNIFIED PAYOUT SYSTEM MIGRATION REPORT');
    buffer.writeln('Generated: ${DateTime.now()}');
    buffer.writeln('=' * 60);
    buffer.writeln();

    try {
      final workers = await AppServices.getAllAgentsStream().first;

      buffer.writeln('Total Workers: ${workers.length}');
      buffer.writeln();
      buffer.writeln('-' * 60);
      buffer.writeln();

      for (var worker in workers) {
        try {
          final verification = await verifyWorkerMigration(worker.uid!);

          buffer.writeln('Worker: ${worker.name ?? 'Unknown'} (${worker.uid})');
          buffer.writeln(
            'Status: ${verification['success'] ? '✅ PASSED' : '❌ FAILED'}',
          );

          if (verification['success'] == true) {
            final actual = verification['actual'];
            buffer.writeln(
              '  Total Available: ${actual['availableEarnings'] + actual['cardTips'] + actual['bonus']}',
            );
            buffer.writeln('  - Earnings: ${actual['availableEarnings']}');
            buffer.writeln('  - Tips: ${actual['cardTips']}');
            buffer.writeln('  - Bonus: ${actual['bonus']}');
          } else {
            buffer.writeln(
              '  Error: ${verification['error'] ?? 'Verification failed'}',
            );
          }

          buffer.writeln();
        } catch (e) {
          buffer.writeln('Worker: ${worker.name ?? 'Unknown'} (${worker.uid})');
          buffer.writeln('Status: ❌ ERROR');
          buffer.writeln('  Error: $e');
          buffer.writeln();
        }
      }

      buffer.writeln('-' * 60);
      buffer.writeln('END OF REPORT');
      buffer.writeln('=' * 60);

      return buffer.toString();
    } catch (e) {
      buffer.writeln('ERROR GENERATING REPORT: $e');
      return buffer.toString();
    }
  }
}
