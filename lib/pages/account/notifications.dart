import 'dart:convert';
import 'dart:developer';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;

  String _currentLanguage = 'en';
  final String _apiKey = 'AIzaSyBl4RQBYM_v-u2Oik_ENyxcGxnvyZGxL2o';
  final Map<String, String> _translationCache = {};

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newLanguage = AppLocalizations.of(context)?.localeName ?? 'en';
    if (newLanguage != _currentLanguage) {
      final oldLanguage = _currentLanguage;
      _currentLanguage = newLanguage;

      // Only reload notifications if language actually changed and we have notifications
      if (oldLanguage != newLanguage && notifications.isNotEmpty) {
        _loadNotifications();
      }
    }
  }

  Future<void> _loadNotifications() async {
    setState(() {
      isLoading = true;
      notifications = [];
    });

    try {
      final notificationsList = await AppServices.getUserNotifications(
        limit: 50,
      );

      // Wait for translations to complete before showing UI
      final translatedNotifications = await _translateNotifications(
        notificationsList,
      );

      setState(() {
        notifications = translatedNotifications;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading notifications: $e')),
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> _translateNotifications(
    List<Map<String, dynamic>> notificationsList,
  ) async {
    if (notificationsList.isEmpty) return notificationsList;

    // First, create basic processed notifications
    final processedNotifications = notificationsList.map((notification) {
      return Map<String, dynamic>.from(notification);
    }).toList();

    try {
      List<String> textsToTranslate = [];
      List<Map<String, dynamic>> translationMap = [];

      for (int i = 0; i < notificationsList.length; i++) {
        final notification = notificationsList[i];
        final title = notification['title']?.toString().trim() ?? '';
        final body = notification['body']?.toString().trim() ?? '';

        Map<String, dynamic> itemMap = {
          'notificationIndex': i,
          'originalTitle': title,
          'originalBody': body,
          'titleIndex': -1,
          'bodyIndex': -1,
        };

        if (title.isNotEmpty) {
          final cacheKey = '${title}_$_currentLanguage';
          if (_translationCache.containsKey(cacheKey)) {
            // Use cached translation
            processedNotifications[i]['title'] = _translationCache[cacheKey];
          } else {
            bool shouldTranslate = false;
            if (_currentLanguage == 'ar') {
              shouldTranslate = _isPrimaryEnglish(title);
            } else {
              shouldTranslate = _containsArabic(title);
            }

            if (shouldTranslate) {
              itemMap['titleIndex'] = textsToTranslate.length;
              textsToTranslate.add(title);
            }
          }
        }

        if (body.isNotEmpty) {
          final cacheKey = '${body}_$_currentLanguage';
          if (_translationCache.containsKey(cacheKey)) {
            // Use cached translation
            processedNotifications[i]['body'] = _translationCache[cacheKey];
          } else {
            bool shouldTranslate = false;
            if (_currentLanguage == 'ar') {
              shouldTranslate = _isPrimaryEnglish(body);
            } else {
              shouldTranslate = _containsArabic(body);
            }

            if (shouldTranslate) {
              itemMap['bodyIndex'] = textsToTranslate.length;
              textsToTranslate.add(body);
            }
          }
        }

        translationMap.add(itemMap);
      }

      List<String> translatedTexts = [];
      if (textsToTranslate.isNotEmpty) {
        log(
          'Translating ${textsToTranslate.length} texts to $_currentLanguage',
        );
        translatedTexts = await _batchTranslateTexts(
          textsToTranslate,
          _currentLanguage,
        );
        log('Translation completed, got ${translatedTexts.length} results');
      }

      // Apply translations to the processed notifications
      if (translatedTexts.isNotEmpty) {
        for (int i = 0; i < translationMap.length; i++) {
          final item = translationMap[i];
          final notificationIndex = item['notificationIndex'] as int;

          if (notificationIndex < processedNotifications.length) {
            final titleIndex = item['titleIndex'] as int;
            if (titleIndex != -1 && titleIndex < translatedTexts.length) {
              final translatedTitle = translatedTexts[titleIndex];
              processedNotifications[notificationIndex]['title'] =
                  translatedTitle;

              _translationCache['${item['originalTitle']}_$_currentLanguage'] =
                  translatedTitle;
            }

            final bodyIndex = item['bodyIndex'] as int;
            if (bodyIndex != -1 && bodyIndex < translatedTexts.length) {
              final translatedBody = translatedTexts[bodyIndex];
              processedNotifications[notificationIndex]['body'] =
                  translatedBody;

              _translationCache['${item['originalBody']}_$_currentLanguage'] =
                  translatedBody;
            }
          }
        }
      }

      return processedNotifications;
    } catch (e) {
      log('Error in translation: $e');
      return processedNotifications; // Return unprocessed notifications on error
    }
  }

  Future<List<String>> _batchTranslateTexts(
    List<String> texts,
    String targetLang,
  ) async {
    if (texts.isEmpty) return [];

    try {
      String sourceLang = targetLang == 'ar' ? 'en' : 'ar';

      final response = await http
          .post(
            Uri.parse(
              'https://translation.googleapis.com/language/translate/v2?key=$_apiKey',
            ),
            headers: {
              'Content-Type': 'application/json',
              'User-Agent': 'AbogalamboApp/1.0',
            },
            body: jsonEncode({
              'q': texts,
              'source': sourceLang,
              'target': targetLang,
              'format': 'text',
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final translations = data['data']?['translations'] as List?;

        if (translations != null) {
          return translations
              .map<String>((t) => t['translatedText']?.toString() ?? '')
              .toList();
        }
      } else {
        log('Translation API error: ${response.statusCode} - ${response.body}');
        throw Exception('Translation API error: ${response.statusCode}');
      }
    } catch (e) {
      log('Batch translation error: $e');

      return texts;
    }

    return texts;
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    final currentLang = _currentLanguage;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.notifications),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
            tooltip: _currentLanguage == 'ar' ? 'تحديث' : 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Debug info (only in development)
          if (kDebugMode)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8.0),
              color: Colors.blue.shade50,
              child: FutureBuilder<String>(
                future: AppServices.getCurrentUserRole(),
                builder: (context, snapshot) {
                  return Text(
                    'Debug: User Role = ${snapshot.data ?? 'Loading...'} | Notifications: ${notifications.length}',
                    style: const TextStyle(fontSize: 12, color: Colors.blue),
                    textAlign: TextAlign.center,
                  );
                },
              ),
            ),
          Expanded(
            child: isLoading
                ? _buildLoadingState(currentLang)
                : notifications.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadNotifications,
                    child: ListView.builder(
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        return _buildNotificationCard(
                          notifications[index],
                          isRTL,
                          currentLang,
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(String currentLang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            _getLocalizedText('loadingNotifications'),
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.noNotifications,
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    Map<String, dynamic> notification,
    bool isRTL,
    String currentLang,
  ) {
    try {
      final createdAt = notification['createdAt'] as Timestamp?;
      final title = notification['title']?.toString().trim();
      final body = notification['body']?.toString().trim();
      final category = notification['category'] ?? 'general';

      final displayTitle = (title?.isNotEmpty == true)
          ? title!
          : (body?.isNotEmpty == true)
          ? body!
          : AppLocalizations.of(context)!.notifications;

      final displayBody = (title?.isNotEmpty == true)
          ? (body?.isNotEmpty == true
                ? body!
                : _getLocalizedText('noAdditionalContent'))
          : _getLocalizedText('tapToViewDetails');

      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        elevation: 2,
        child: ListTile(
          leading: Tooltip(
            message: _getCategoryName(category),
            child: CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(_getCategoryIcon(category), color: Colors.white),
            ),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  displayTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: isRTL ? TextAlign.right : TextAlign.left,
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: isRTL
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Text(
                displayBody,
                style: TextStyle(color: Colors.grey[700]),
                textAlign: isRTL ? TextAlign.right : TextAlign.left,
              ),
              if (createdAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  _formatTime(createdAt.toDate()),
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  textAlign: isRTL ? TextAlign.right : TextAlign.left,
                ),
              ],
            ],
          ),
        ),
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'booking':
        return Icons.calendar_today;
      case 'service':
        return Icons.build;
      case 'payment':
        return Icons.payment;
      case 'order':
        return Icons.shopping_cart;
      case 'account':
        return Icons.person;
      case 'promotion':
        return Icons.local_offer;
      default:
        return Icons.notifications;
    }
  }

  String _getCategoryName(String category) {
    if (_currentLanguage == 'ar') {
      switch (category.toLowerCase()) {
        case 'booking':
          return 'حجز';
        case 'service':
          return 'خدمة';
        case 'payment':
          return 'دفع';
        case 'order':
          return 'طلب';
        case 'account':
          return 'حساب';
        case 'promotion':
          return 'عرض';
        default:
          return 'إشعار';
      }
    } else {
      switch (category.toLowerCase()) {
        case 'booking':
          return 'Booking';
        case 'service':
          return 'Service';
        case 'payment':
          return 'Payment';
        case 'order':
          return 'Order';
        case 'account':
          return 'Account';
        case 'promotion':
          return 'Promotion';
        default:
          return 'Notification';
      }
    }
  }

  bool _containsArabic(String text) {
    if (text.isEmpty) return false;
    return text.runes.any((rune) => rune >= 0x0600 && rune <= 0x06FF);
  }

  bool _isPrimaryEnglish(String text) {
    if (text.isEmpty) return true;
    final englishChars = text.runes
        .where(
          (rune) =>
              (rune >= 0x0041 && rune <= 0x005A) ||
              (rune >= 0x0061 && rune <= 0x007A),
        )
        .length;
    final totalChars = text.replaceAll(RegExp(r'[^\w]'), '').length;
    return totalChars == 0 || (englishChars / totalChars) > 0.5;
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return _formatTimeUnit(difference.inDays, 'day');
    } else if (difference.inHours > 0) {
      return _formatTimeUnit(difference.inHours, 'hour');
    } else if (difference.inMinutes > 0) {
      return _formatTimeUnit(difference.inMinutes, 'minute');
    } else {
      return _getLocalizedText('justNow');
    }
  }

  String _formatTimeUnit(int value, String unit) {
    if (_currentLanguage == 'ar') {
      String unitText;
      switch (unit) {
        case 'day':
          unitText = value == 1
              ? 'يوم'
              : value == 2
              ? 'يومين'
              : 'أيام';
          break;
        case 'hour':
          unitText = value == 1
              ? 'ساعة'
              : value == 2
              ? 'ساعتين'
              : 'ساعات';
          break;
        case 'minute':
          unitText = value == 1
              ? 'دقيقة'
              : value == 2
              ? 'دقيقتين'
              : 'دقائق';
          break;
        default:
          unitText = unit;
      }
      return 'منذ $value $unitText';
    } else {
      String unitText = _getLocalizedText(unit);
      if (value > 1) unitText += 's';
      return '$value $unitText ${_getLocalizedText('ago')}';
    }
  }

  String _getLocalizedText(String key) {
    final localizations = AppLocalizations.of(context);

    switch (key) {
      case 'noAdditionalContent':
        return _currentLanguage == 'ar'
            ? 'لا يوجد محتوى إضافي'
            : 'No additional content';
      case 'tapToViewDetails':
        return _currentLanguage == 'ar'
            ? 'اضغط لعرض التفاصيل'
            : 'Tap to view details';
      case 'day':
        return localizations?.day ?? (_currentLanguage == 'ar' ? 'يوم' : 'day');
      case 'hour':
        return localizations?.hour ??
            (_currentLanguage == 'ar' ? 'ساعة' : 'hour');
      case 'minute':
        return localizations?.minute ??
            (_currentLanguage == 'ar' ? 'دقيقة' : 'minute');
      case 'ago':
        return _currentLanguage == 'ar' ? 'منذ' : 'ago';
      case 'justNow':
        return localizations?.justNow ??
            (_currentLanguage == 'ar' ? 'الآن' : 'Just now');
      case 'loadingNotifications':
        return _currentLanguage == 'ar'
            ? 'جاري تحميل الإشعارات...'
            : 'Loading notifications...';
      case 'refreshing':
        return _currentLanguage == 'ar' ? 'جاري التحديث...' : 'Refreshing...';
      default:
        return key;
    }
  }
}
