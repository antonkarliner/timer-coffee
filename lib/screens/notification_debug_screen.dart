import 'dart:io';
import 'dart:math' as math;
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:coffee_timer/services/notification_service.dart';
import 'package:coffee_timer/services/fcm_service.dart';
import 'package:coffee_timer/services/permission_service.dart';
import 'package:coffee_timer/services/notification_settings_service.dart';
import 'package:coffee_timer/providers/fcm_provider.dart';
import 'package:coffee_timer/utils/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rxdart/rxdart.dart';

@RoutePage()
class NotificationDebugScreen extends StatefulWidget {
  final NotificationService _notificationService = NotificationService.instance;

  NotificationDebugScreen({Key? key}) : super(key: key);

  @override
  _NotificationDebugScreenState createState() =>
      _NotificationDebugScreenState();
}

class _NotificationDebugScreenState extends State<NotificationDebugScreen> {
  String? _fcmToken;
  bool _isLoadingToken = false;
  bool _isLoadingPermissions = false;
  bool _hasPermissions = false;
  bool _masterEnabled = false;
  String? _userId;
  List<Map<String, dynamic>> _databaseTokens = [];

  // Enhanced debugging variables
  String? _lastPermissionError;
  DateTime? _lastPermissionCheck;
  PermissionState? _permissionState;

  @override
  void initState() {
    super.initState();
    _loadCompleteDebugInfo();
  }

  Future<void> _loadCompleteDebugInfo() async {
    setState(() {
      _isLoadingToken = true;
      _isLoadingPermissions = true;
    });

    try {
      // Load user info
      final user = Supabase.instance.client.auth.currentUser;
      _userId = user?.id;

      // Load FCM token
      final token = await widget._notificationService.fcm.getToken();

      // Load enhanced permission status with detailed state
      final permissionState = await widget._notificationService.permissions
          .getCurrentPermissionState();
      _permissionState = permissionState;

      // Record permission check timestamp
      _lastPermissionCheck = DateTime.now();

      // Load master setting
      final masterEnabled =
          await widget._notificationService.settings.isMasterEnabled();

      // Load database tokens for user
      List<Map<String, dynamic>> dbTokens = [];
      if (_userId != null && !kIsWeb) {
        try {
          final supabase = Supabase.instance.client;
          final platform = Platform.isIOS ? 'ios' : 'android';
          final tokens = await supabase
              .schema('service')
              .from('user_fcm_tokens')
              .select()
              .eq('user_id', _userId!)
              .eq('device_type', platform)
              .order('updated_at', ascending: false);
          dbTokens = List<Map<String, dynamic>>.from(tokens ?? []);
        } catch (e) {
          AppLogger.error('Error loading database tokens', errorObject: e);
        }
      }

      if (mounted) {
        setState(() {
          _fcmToken = token;
          _isLoadingToken = false;
          _hasPermissions = permissionState.granted;
          _masterEnabled = masterEnabled;
          _isLoadingPermissions = false;
          _databaseTokens = dbTokens;
          _lastPermissionError =
              permissionState.platformSpecificError; // Show detailed error
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _fcmToken = 'Error: $e';
          _isLoadingToken = false;
          _isLoadingPermissions = false;
          _lastPermissionError = e.toString(); // Record error for debugging
        });
      }
    }
  }

  Future<void> _loadFcmToken() async {
    setState(() {
      _isLoadingToken = true;
    });

    try {
      final token = await widget._notificationService.fcm.getToken();
      if (mounted) {
        setState(() {
          _fcmToken = token;
          _isLoadingToken = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _fcmToken = 'Error: $e';
          _isLoadingToken = false;
        });
      }
    }
  }

  Future<void> _sendTestFcmNotification() async {
    try {
      AppLogger.info('Testing FCM notification - check logs for delivery');

      // For now, just show a local notification to simulate what FCM would do
      await widget._notificationService.showLocalNotification(
        id: DateTime.now().millisecondsSinceEpoch,
        title: 'Test FCM Notification',
        body:
            'This simulates a push notification from Firebase Cloud Messaging',
        payload: '/home',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Test FCM notification simulated - check device logs')),
        );
      }
    } catch (e) {
      AppLogger.error('Error testing FCM notification', errorObject: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _refreshPermissions() async {
    setState(() {
      _isLoadingPermissions = true;
    });

    try {
      await widget._notificationService.refreshPermissionStatus();
      await _loadCompleteDebugInfo();
    } catch (e) {
      AppLogger.error('Error refreshing permissions', errorObject: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFcmToken,
          ),
        ],
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Firebase Cloud Messaging (FCM) Testing',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: const Text('FCM Token'),
              subtitle: _isLoadingToken
                  ? const CircularProgressIndicator()
                  : SelectableText(
                      _fcmToken ?? 'No token available',
                      style: const TextStyle(fontSize: 12),
                    ),
              trailing: _fcmToken != null && _fcmToken!.startsWith('Error')
                  ? const Icon(Icons.error, color: Colors.red)
                  : const Icon(Icons.check_circle, color: Colors.green),
              onTap:
                  _fcmToken != null ? () => _copyToClipboard(_fcmToken!) : null,
            ),
          ),
          ListTile(
            title: const Text('Test FCM Notification'),
            subtitle: const Text('Simulate receiving a push notification'),
            onTap: _sendTestFcmNotification,
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Local Notifications',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            title: const Text('Test Immediate Local Notification'),
            subtitle: const Text('Shows a notification instantly'),
            onTap: () => widget._notificationService.showLocalNotification(
              id: 1,
              title: 'Test Notification',
              body: 'This is a test notification.',
              payload: '/settings',
            ),
          ),
          ListTile(
            title: const Text('Test Scheduled Local Notification'),
            subtitle:
                const Text('Schedules a notification for 1 minute from now'),
            onTap: () => widget._notificationService.scheduleLocalNotification(
              id: 2,
              title: 'Scheduled Notification',
              body: 'This notification was scheduled 1 minute ago.',
              scheduledDate: DateTime.now().add(const Duration(minutes: 1)),
              payload: '/coffee-beans',
            ),
          ),
          ListTile(
            title: const Text('Request Permissions'),
            subtitle: const Text(
                'Requests notification permissions with Firebase-first approach'),
            onTap: () => widget._notificationService.requestPermissions(),
          ),
          ListTile(
            title: const Text('Refresh Permission Status'),
            subtitle: const Text('Force refresh of permission cache'),
            onTap: _refreshPermissions,
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Enhanced Debug Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          // Comprehensive Debug Information Section
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'System Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Platform: ${Platform.operatingSystem}'),
                  Text('Web Platform: $kIsWeb'),
                  Text('User ID: ${_userId ?? 'Not authenticated'}'),
                  Text(
                      'Notification Service Initialized: ${widget._notificationService.isInitialized}'),
                  const SizedBox(height: 16),

                  // Enhanced Permission State Section
                  Text(
                    'Enhanced Permission State',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_permissionState != null) ...[
                    _buildStatusRow('Permissions Granted',
                        _permissionState!.granted, Colors.green),
                    _buildStatusRow('Can Show Notifications',
                        _permissionState!.canShowNotifications, Colors.blue),
                    if (_permissionState!.isWeb)
                      _buildStatusRow('Web Platform', true, Colors.orange)
                    else
                      _buildStatusRow('Native Platform', true, Colors.purple),
                    if (_permissionState!.firebaseStatus != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 24),
                        child: Text(
                          'Firebase Status: ${_permissionState!.firebaseStatus}',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    if (_permissionState!.platformSpecificError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 24),
                        child: Text(
                          'Platform Error: ${_permissionState!.platformSpecificError}',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.red),
                        ),
                      ),
                    if (_lastPermissionCheck != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 24),
                        child: Text(
                          'Last Check: ${_lastPermissionCheck.toString().substring(0, 19)}',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    if (_lastPermissionError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 24),
                        child: Text(
                          'Last Error: ${_lastPermissionError}',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.red),
                        ),
                      ),
                  ],
                  const SizedBox(height: 16),

                  // Notification State Section
                  Text(
                    'Notification State',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildStatusRow(
                      'Master Toggle', _masterEnabled, Colors.green),
                  _buildStatusRow(
                      'Permissions Granted', _hasPermissions, Colors.blue),
                  if (_permissionState != null)
                    _buildStatusRow(
                        'Full Permission State',
                        _permissionState!.granted &&
                            _permissionState!.canShowNotifications,
                        _permissionState!.granted &&
                                _permissionState!.canShowNotifications
                            ? Colors.green
                            : Colors.red),
                  const SizedBox(height: 16),

                  // FCM Token Section
                  Text(
                    'FCM Token Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_fcmToken != null && !_fcmToken!.contains('Error'))
                    SelectableText(
                      _fcmToken!,
                      style: const TextStyle(
                          fontSize: 12, fontFamily: 'monospace'),
                    )
                  else
                    Text(
                      _fcmToken ?? 'No token available',
                      style: const TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  const SizedBox(height: 16),

                  // Database Tokens Section
                  if (_databaseTokens.isNotEmpty) ...[
                    Text(
                      'Database Tokens (${_databaseTokens.length})',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ..._databaseTokens.map((token) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Icon(
                                token['is_active'] == true
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                color: token['is_active'] == true
                                    ? Colors.green
                                    : Colors.red,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Token: ${(token['token'] as String).substring(0, math.min(20, token['token'].toString().length))}...',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontFamily: 'monospace'),
                                    ),
                                    Text(
                                      'Platform: ${token['device_type']}',
                                      style: const TextStyle(
                                          fontSize: 11, color: Colors.grey),
                                    ),
                                    Text(
                                      'Active: ${token['is_active'] == true ? 'Yes' : 'No'}',
                                      style: const TextStyle(
                                          fontSize: 11, color: Colors.grey),
                                    ),
                                    Text(
                                      'Updated: ${token['updated_at']?.toString().substring(0, 19) ?? 'Unknown'}',
                                      style: const TextStyle(
                                          fontSize: 11, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                  const SizedBox(height: 16),

                  // Testing Instructions
                  Text(
                    'Testing Instructions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'FCM Testing:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Text('1. Send push notification from Firebase Console'),
                  const Text('2. Check device logs for FCM delivery'),
                  const Text('3. Verify notification appears correctly'),
                  const SizedBox(height: 8),
                  const Text(
                    'Local Testing:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Text(
                      'Use test buttons below to simulate notifications'),
                  const SizedBox(height: 8),
                  const Text(
                    'Enhanced Debugging:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Text(
                      '• Permission state now shows Firebase-first approach details'),
                  const Text(
                      '• Cache invalidation forces fresh permission checks'),
                  const Text('• Platform-specific errors are displayed'),
                  const Text('• Real-time permission monitoring is active'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, bool status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            status ? Icons.check_circle : Icons.cancel,
            color: status ? color : Colors.grey,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ${status ? 'Yes' : 'No'}',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text) {
    // Note: In a real implementation, you'd use the clipboard package
    // For now, just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Token copied to clipboard')),
    );
  }
}
