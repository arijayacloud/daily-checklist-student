import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '/config.dart';
import '/laravel_api/models/notification_model.dart';
import '/laravel_api/providers/notification_provider.dart';
import '/laravel_api/providers/auth_provider.dart';
import '/laravel_api/providers/api_provider.dart';
import '/lib/theme/app_theme.dart';
import '/services/fcm_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Laravel API
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final notificationProvider = Provider.of<NotificationProvider>(
        context,
        listen: false,
      );

      // Untuk Laravel API, fetchNotifications sudah dilakukan saat update(user) di provider
      if (authProvider.user != null && !authProvider.user!.isTeacher) {
        // Langsung fetch notifications saja karena childId sudah diambil di API
        notificationProvider.fetchNotifications();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_email_read),
            tooltip: 'Tandai semua sudah dibaca',
            onPressed: () {
              Provider.of<NotificationProvider>(
                context,
                listen: false,
              ).markAllAsRead();
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_alert),
            tooltip: 'Tambah Notifikasi Uji Coba',
            onPressed: () {
              _showAddTestNotificationDialog(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.send),
            tooltip: 'Kirim FCM Notification',
            onPressed: () {
              _showSendFCMNotificationDialog(context);
            },
          ),
        ],
      ),
      body: _buildNotifications(),
    );
  }

  Widget _buildNotifications() {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(provider.error!, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.fetchNotifications(),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        }

        if (provider.notifications.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          itemCount: provider.notifications.length,
          itemBuilder: (context, index) {
            final notification = provider.notifications[index];
            return _buildNotificationItem(context, notification, provider);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: AppTheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada notifikasi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Notifikasi baru akan muncul di sini',
            style: TextStyle(color: AppTheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddTestNotificationDialog(context),
            icon: const Icon(Icons.add_alert),
            label: const Text('Tambah Notifikasi Uji Coba'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    NotificationModel notification,
    NotificationProvider provider,
  ) {
    final formattedDate = DateFormat(
      'dd MMM yyyy HH:mm',
      'id_ID',
    ).format(notification.createdAt);

    return _buildNotificationItemLayout(
      context: context,
      id: notification.id,
      title: notification.title,
      message: notification.message,
      formattedDate: formattedDate,
      type: notification.type,
      isRead: notification.isRead,
      onTap: () {
        if (!notification.isRead) {
          provider.markAsRead(notification.id);
        }
        _handleNotificationTap(context, notification);
      },
      onDismissed: (_) {
        provider.deleteNotification(notification.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notifikasi telah dihapus')),
        );
      },
    );
  }

  Widget _buildNotificationItemLayout({
    required BuildContext context,
    required String id,
    required String title,
    required String message,
    required String formattedDate,
    required String type,
    required bool isRead,
    required Function() onTap,
    required Function(DismissDirection) onDismissed,
  }) {
    return Dismissible(
      key: Key(id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: onDismissed,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: isRead ? 1 : 3,
        color:
            isRead
                ? null
                : AppTheme.primaryContainer.withOpacity(0.3),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getNotificationColor(
                          type,
                        ).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getNotificationIcon(type),
                        size: 24,
                        color: _getNotificationColor(type),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontWeight:
                                  isRead
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isRead)
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: TextStyle(
                    color:
                        isRead
                            ? AppTheme.onSurfaceVariant
                            : AppTheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'new_plan':
        return Colors.blue;
      case 'activity_completed':
        return AppTheme.success;
      case 'reminder':
        return Colors.orange;
      case 'test':
        return Colors.purple;
      default:
        return AppTheme.primary;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'new_plan':
        return Icons.event_note;
      case 'activity_completed':
        return Icons.assignment_turned_in;
      case 'reminder':
        return Icons.alarm;
      case 'test':
        return Icons.bug_report;
      default:
        return Icons.notifications;
    }
  }

  void _handleNotificationTap(
    BuildContext context,
    NotificationModel notification,
  ) {
    // Implementasi navigasi ke halaman terkait notifikasi
    // Misalnya, jika type adalah 'new_plan', navigasi ke detail plan
    switch (notification.type) {
      case 'new_plan':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navigasi ke rencana ID: ${notification.relatedId}'),
          ),
        );
        break;
      case 'activity_completed':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navigasi ke aktivitas ID: ${notification.relatedId}'),
          ),
        );
        break;
      default:
        // Tidak ada navigasi khusus
        break;
    }
  }

  void _showAddTestNotificationDialog(BuildContext context) {
    final titleController = TextEditingController(text: 'Notifikasi Uji Coba');
    final messageController = TextEditingController(
      text: 'Ini adalah notifikasi untuk keperluan pengujian.',
    );
    String selectedType = 'test';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Tambah Notifikasi Uji Coba'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Judul',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: messageController,
                    decoration: const InputDecoration(
                      labelText: 'Pesan',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  const Text('Tipe Notifikasi:'),
                  StatefulBuilder(
                    builder: (context, setState) {
                      return Column(
                        children: [
                          RadioListTile<String>(
                            title: const Text('Uji Coba'),
                            value: 'test',
                            groupValue: selectedType,
                            onChanged: (value) {
                              setState(() => selectedType = value!);
                            },
                          ),
                          RadioListTile<String>(
                            title: const Text('Perencanaan Baru'),
                            value: 'new_plan',
                            groupValue: selectedType,
                            onChanged: (value) {
                              setState(() => selectedType = value!);
                            },
                          ),
                          RadioListTile<String>(
                            title: const Text('Aktivitas Selesai'),
                            value: 'activity_completed',
                            groupValue: selectedType,
                            onChanged: (value) {
                              setState(() => selectedType = value!);
                            },
                          ),
                          RadioListTile<String>(
                            title: const Text('Pengingat'),
                            value: 'reminder',
                            groupValue: selectedType,
                            onChanged: (value) {
                              setState(() => selectedType = value!);
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  final title = titleController.text.trim();
                  final message = messageController.text.trim();

                  if (title.isEmpty || message.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Judul dan pesan wajib diisi'),
                      ),
                    );
                    return;
                  }

                  final authProvider = Provider.of<AuthProvider>(
                    context, 
                    listen: false,
                  );
                  if (authProvider.user != null) {
                    Provider.of<NotificationProvider>(
                      context,
                      listen: false,
                    ).createNotification(
                      userId: authProvider.user!.id,
                      title: title,
                      message: message,
                      type: selectedType,
                    );
                  }

                  Navigator.pop(context);
                },
                child: const Text('Tambah'),
              ),
            ],
          ),
    );
  }

  void _showSendFCMNotificationDialog(BuildContext context) {
    final titleController = TextEditingController(text: 'FCM Test Notification');
    final messageController = TextEditingController(
      text: 'Ini adalah notifikasi FCM untuk pengujian.',
    );
    final tokenController = TextEditingController();
    String selectedType = 'test';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kirim FCM Notification'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: 'Pesan',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: tokenController,
                decoration: const InputDecoration(
                  labelText: 'FCM Token (opsional)',
                  border: OutlineInputBorder(),
                  hintText: 'Kosongkan untuk menggunakan token saat ini',
                ),
              ),
              const SizedBox(height: 16),
              const Text('Tipe Notifikasi:'),
              StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    children: [
                      RadioListTile<String>(
                        title: const Text('Uji Coba'),
                        value: 'test',
                        groupValue: selectedType,
                        onChanged: (value) {
                          setState(() => selectedType = value!);
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('Perencanaan Baru'),
                        value: 'new_plan',
                        groupValue: selectedType,
                        onChanged: (value) {
                          setState(() => selectedType = value!);
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('Aktivitas Selesai'),
                        value: 'activity_completed',
                        groupValue: selectedType,
                        onChanged: (value) {
                          setState(() => selectedType = value!);
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('Pengingat'),
                        value: 'reminder',
                        groupValue: selectedType,
                        onChanged: (value) {
                          setState(() => selectedType = value!);
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = titleController.text.trim();
              final message = messageController.text.trim();
              final token = tokenController.text.trim();

              if (title.isEmpty || message.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Judul dan pesan wajib diisi'),
                  ),
                );
                return;
              }

              await _sendFCMNotification(
                context: context,
                title: title,
                body: message,
                type: selectedType,
                token: token.isNotEmpty ? token : null,
              );

              Navigator.pop(context);
            },
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendFCMNotification({
    required BuildContext context,
    required String title,
    required String body,
    required String type,
    String? token,
  }) async {
    try {
      // If no token is provided, get the current device token
      if (token == null || token.isEmpty) {
        token = await FirebaseMessaging.instance.getToken();
      }

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak dapat mendapatkan token FCM'),
          ),
        );
        return;
      }

      // Prepare notification data
      final data = {
        'message': {
          'token': token,
          'notification': {
            'title': title,
            'body': body,
          },
          'data': {
            'type': type,
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'id': '1',
            'status': 'done',
          },
          'android': {
            'priority': 'high',
            'notification': {
              'notification_priority': 'PRIORITY_MAX',
              'default_sound': true,
              'default_vibrate_timings': true,
            },
          },
          'apns': {
            'payload': {
              'aps': {
                'sound': 'default',
              },
            },
          },
        }
      };

      // Send the notification using the API provider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final apiProvider = Provider.of<ApiProvider>(context, listen: false);
      
      if (apiProvider.token != null) {
        // First approach: Send via backend API
        final response = await http.post(
          Uri.parse('${apiProvider.baseUrl}/send-notification'),
          headers: {
            'Authorization': 'Bearer ${apiProvider.token}',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'title': title,
            'body': body,
            'data': {
              'type': type,
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            },
            'token': token,
          }),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notifikasi FCM berhasil dikirim'),
            ),
          );
        } else {
          // Try direct FCM approach as fallback
          await _sendDirectFCMNotification(
            context: context,
            title: title,
            body: body,
            type: type,
            token: token,
          );
        }
      } else {
        // Fallback to direct FCM API call
        await _sendDirectFCMNotification(
          context: context,
          title: title,
          body: body,
          type: type,
          token: token,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
        ),
      );
    }
  }

  // Alternative method to send notifications directly using FCM
  Future<void> _sendDirectFCMNotification({
    required BuildContext context,
    required String title,
    required String body,
    required String type,
    required String token,
  }) async {
    try {
      // For testing purposes, we'll show a local notification
      // In a real implementation, this would use the FCM HTTP v1 API
      // But for demo purposes, we'll use the local notification functionality
      
      // Create a local instance of FlutterLocalNotificationsPlugin
      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();
      
      // Initialize the plugin
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings();
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );
      
      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          print('Notification tapped: ${response.payload}');
        },
      );
      
      // Show a local notification to simulate FCM notification
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'fcm_test_channel',
        'Test FCM Channel',
        channelDescription: 'This channel is used for testing FCM notifications',
        importance: Importance.high,
        priority: Priority.high,
      );
      
      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );
      
      // Show the notification
      await flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecond,
        title,
        body,
        notificationDetails,
        payload: json.encode({
          'type': type,
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        }),
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notifikasi lokal berhasil ditampilkan'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error menampilkan notifikasi lokal: $e'),
        ),
      );
    }
  }
}
