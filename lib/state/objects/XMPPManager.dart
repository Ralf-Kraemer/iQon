// xmpp_manager.dart
import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:xmpp_plugin/xmpp_plugin.dart';
import 'package:xmpp_plugin/models/message_model.dart';
import 'package:xmpp_plugin/models/connection_event.dart';
import 'package:xmpp_plugin/error_response_event.dart';
import 'package:xmpp_plugin/success_response_event.dart';
import 'package:xmpp_plugin/models/present_mode.dart';
import 'package:xmpp_plugin/models/chat_state_model.dart';

class XmppManager with WidgetsBindingObserver {
  XmppConnection? _connection;
  XmppListenerImpl? _listener;

  // --- Reactive Streams ---
  final _messagesController = StreamController<MessageChat>.broadcast();
  Stream<MessageChat> get messages => _messagesController.stream;

  final _connectionController = StreamController<ConnectionEvent>.broadcast();
  Stream<ConnectionEvent> get connectionEvents => _connectionController.stream;

  final _presenceController = StreamController<PresentModel>.broadcast();
  Stream<PresentModel> get presenceChanges => _presenceController.stream;

  final _errorsController = StreamController<ErrorResponseEvent>.broadcast();
  Stream<ErrorResponseEvent> get errors => _errorsController.stream;

  final _successController = StreamController<SuccessResponseEvent>.broadcast();
  Stream<SuccessResponseEvent> get successes => _successController.stream;

  bool _isConnected = false;
  bool get isConnected => _isConnected;
  bool _isConnecting = false;

  XmppManager() {
    WidgetsBinding.instance.addObserver(this);
  }

  /// App lifecycle handling
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_isConnected && !_isConnecting) {
      _reconnectIfNeeded();
    }
  }

  /// Connect to XMPP server
  Future<void> connect({
    required String username,
    required String password,
    required String host,
    String resource = 'Flutter',
    int port = 5222,
    bool requireSSL = false,
    bool autoDeliveryReceipt = true,
    bool useStreamManagement = false,
    bool automaticReconnection = true,
  }) async {
    if (_isConnecting || _isConnected) return;

    _isConnecting = true;

    final config = {
      'user_jid': '$username@$host/$resource',
      'password': password,
      'host': host,
      'port': port,
      'requireSSLConnection': requireSSL,
      'autoDeliveryReceipt': autoDeliveryReceipt,
      'useStreamManagement': useStreamManagement,
      'automaticReconnection': automaticReconnection,
    };

    _connection = XmppConnection(config);

    // Remove old listener if exists
    if (_listener != null) {
      XmppConnection.removeListener(_listener!);
    }

    _listener = XmppListenerImpl(
      onMessage: _messagesController.add,
      onConnection: _handleConnectionEvent,
      onError: _errorsController.add,
      onSuccess: _successController.add,
      onPresence: _presenceController.add,
    );

    XmppConnection.addListener(_listener!);

    try {
      await _connection!.start((error) {
        _errorsController.add(ErrorResponseEvent(error: error));
        _isConnected = false;
      });

      await _connection!.login();
    } catch (e) {
      _errorsController.add(ErrorResponseEvent(error: e.toString()));
      _isConnected = false;
    } finally {
      _isConnecting = false;
    }
  }

  void _handleConnectionEvent(ConnectionEvent event) async {
    _connectionController.add(event);

    final connected = _checkConnected(event);
    if (connected && !_isConnected) {
      _isConnected = true;
      await _sendInitialPresence();
    } else if (!connected && _isConnected) {
      _isConnected = false;
    }
  }

  bool _checkConnected(ConnectionEvent event) {
    final typeStr = event.type.toString().toLowerCase();
    return typeStr.contains('authenticated') || typeStr.contains('success');
  }

  Future<void> _sendInitialPresence() async {
    if (_connection == null || !_isConnected) return;
    try {
      await _connection!.changePresenceType('available', 'chat');
    } catch (e) {
      _errorsController.add(ErrorResponseEvent(error: e.toString()));
    }
  }

  /// Change presence mode
  Future<void> changePresence(String mode) async {
    if (_connection == null || !_isConnected) return;
    try {
      await _connection!.changePresenceType('available', mode);
    } catch (e) {
      _errorsController.add(ErrorResponseEvent(error: e.toString()));
    }
  }

  /// Send a chat message
  Future<void> sendMessage(String to, String body) async {
    if (_connection == null || !_isConnected) {
      _errorsController.add(ErrorResponseEvent(error: 'Not connected'));
      return;
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final id = 'msg_$timestamp';
    try {
      await _connection!.sendMessage(to, body, id, timestamp);
    } catch (e) {
      _errorsController.add(ErrorResponseEvent(error: e.toString()));
    }
  }

  Future<void> _reconnectIfNeeded() async {
    if (_connection != null && !_isConnected) {
      try {
        await _connection!.login();
      } catch (e) {
        _errorsController.add(ErrorResponseEvent(error: 'Reconnect failed: $e'));
      }
    }
  }

  /// Dispose all resources
  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);

    if (_listener != null) {
      XmppConnection.removeListener(_listener!);
      _listener = null;
    }

    try {
      await _connection?.logout();
    } catch (_) {}

    await _messagesController.close();
    await _connectionController.close();
    await _presenceController.close();
    await _errorsController.close();
    await _successController.close();

    _isConnected = false;
    _isConnecting = false;
  }
}

/// Listener implementation using Streams
class XmppListenerImpl implements DataChangeEvents {
  final void Function(MessageChat) onMessage;
  final void Function(ConnectionEvent) onConnection;
  final void Function(ErrorResponseEvent) onError;
  final void Function(SuccessResponseEvent) onSuccess;
  final void Function(PresentModel) onPresence;

  XmppListenerImpl({
    required this.onMessage,
    required this.onConnection,
    required this.onError,
    required this.onSuccess,
    required this.onPresence,
  });

  @override
  void onChatMessage(MessageChat m) => onMessage(m);

  @override
  void onNormalMessage(MessageChat m) => onMessage(m);

  @override
  void onGroupMessage(MessageChat m) => onMessage(m);

  @override
  void onConnectionEvents(ConnectionEvent e) => onConnection(e);

  @override
  void onXmppError(ErrorResponseEvent e) => onError(e);

  @override
  void onSuccessEvent(SuccessResponseEvent e) => onSuccess(e);

  @override
  void onPresenceChange(PresentModel? p) {
    if (p != null) onPresence(p);
  }

  @override
  void onChatStateChange(ChatState c) {}
}
