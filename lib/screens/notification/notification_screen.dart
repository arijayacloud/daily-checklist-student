import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '/models/notification_model.dart';
import '/providers/notification_provider.dart';
import '/lib/theme/app_theme.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(
        context,
        listen: false,
      ).fetchNotifications();
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
            tooltip: 'Tandai semua dibaca',
            onPressed: () {
              Provider.of<NotificationProvider>(
                context,
                listen: false,
              ).markAllAsRead();
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_alert),
            tooltip: 'Tambah Notifikasi Test',
            onPressed: () {
              _showAddTestNotificationDialog(context);
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
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
                    label: const Text('Tambah Notifikasi Test'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: provider.notifications.length,
            itemBuilder: (context, index) {
              final notification = provider.notifications[index];
              return _buildNotificationItem(context, notification, provider);
            },
          );
        },
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
    ).format(notification.createdAt.toDate());

    return Dismissible(
      key: Key(notification.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        provider.deleteNotification(notification.id);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Notifikasi dihapus')));
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: notification.isRead ? 1 : 3,
        color:
            notification.isRead
                ? null
                : AppTheme.primaryContainer.withOpacity(0.3),
        child: InkWell(
          onTap: () {
            if (!notification.isRead) {
              provider.markAsRead(notification.id);
            }
            _handleNotificationTap(context, notification);
          },
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
                          notification.type,
                        ).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getNotificationIcon(notification.type),
                        size: 24,
                        color: _getNotificationColor(notification.type),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight:
                                  notification.isRead
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
                    if (!notification.isRead)
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
                  notification.message,
                  style: TextStyle(
                    color:
                        notification.isRead
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
            content: Text('Navigasi ke plan ID: ${notification.relatedId}'),
          ),
        );
        break;
      case 'activity_completed':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Navigasi ke aktivitas ID: ${notification.relatedId}',
            ),
          ),
        );
        break;
      default:
        // Tidak ada navigasi khusus
        break;
    }
  }

  void _showAddTestNotificationDialog(BuildContext context) {
    final titleController = TextEditingController(text: 'Notifikasi Test');
    final messageController = TextEditingController(
      text: 'Ini adalah notifikasi untuk keperluan testing.',
    );
    String selectedType = 'test';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Tambah Notifikasi Test'),
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
                            title: const Text('Test'),
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
                        content: Text('Judul dan pesan harus diisi'),
                      ),
                    );
                    return;
                  }

                  Provider.of<NotificationProvider>(
                    context,
                    listen: false,
                  ).addTestNotification(
                    title: title,
                    message: message,
                    type: selectedType,
                  );

                  Navigator.pop(context);
                },
                child: const Text('Tambah'),
              ),
            ],
          ),
    );
  }
}
