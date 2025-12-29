import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:xmpp_plugin/xmpp_plugin.dart';
import 'package:xmpp_plugin/models/message_model.dart';
import 'package:xmpp_plugin/models/connection_event.dart';
import 'package:xmpp_plugin/error_response_event.dart';
import 'package:xmpp_plugin/success_response_event.dart';
import 'package:xmpp_plugin/models/present_mode.dart';
import 'package:xmpp_plugin/models/chat_state_model.dart';
import 'package:async/async.dart'; // For StreamGroup

class XmppManager with WidgetsBindingObserver {
  XmppConnection? _connection;
  XmppListenerAdvanced? _listener;

  // --- Reactive Streams ---
  final _messagesController = StreamController<MessageChat>.broadcast();
  final _carbonsController = StreamController<MessageChat>.broadcast();
  final _archiveController = StreamController<MessageChat>.broadcast();
  final _chatStateController = StreamController<ChatState>.broadcast();
  final _connectionController = StreamController<ConnectionEvent>.broadcast();
  final _presenceController = StreamController<PresentModel>.broadcast();
  final _errorsController = StreamController<ErrorResponseEvent>.broadcast();
  final _successController = StreamController<SuccessResponseEvent>.broadcast();

  // --- Combined stream for all messages ---
  late final Stream<MessageChat> allMessages;

  bool _isConnected = false;
  bool get isConnected => _isConnected;
  bool _isConnecting = false;

  XmppManager() {
    WidgetsBinding.instance.addObserver(this);

    // Merge all messages into one stream for UI consumption
    allMessages = StreamGroup.merge([
      _messagesController.stream,
      _carbonsController.stream,
      _archiveController.stream,
    ]);
  }

  // --- Lifecycle handling ---
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_isConnected && !_isConnecting) {
      _reconnectIfNeeded();
    }
  }

  /// Connect & initialize XMPP
  Future<void> connect({
    required String username,
    required String password,
    required String host,
    String resource = 'Flutter',
    int port = 5222,
    bool requireSSL = false,
    bool autoDeliveryReceipt = true,
    bool useStreamManagement = true,
    bool automaticReconnection = true,
    bool enableMessageCarbons = true,
    bool enableChatStates = true,
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

    if (_listener != null) {
      XmppConnection.removeListener(_listener!);
    }

    _listener = XmppListenerAdvanced(
      onMessage: _safeAddMessage,
      onConnection: _handleConnectionEvent,
      onError: _safeAddError,
      onSuccess: _safeAddSuccess,
      onPresence: _safeAddPresence,
      onCarbonMessage: enableMessageCarbons ? _safeAddCarbon : (_) {},
      onArchivedMessage: _safeAddArchive,
      onChatState: enableChatStates ? _safeAddChatState : (_) {},
    );

    XmppConnection.addListener(_listener!);

    try {
      await _connection!.start((error) {
        _errorsController.add(ErrorResponseEvent(error: error));
        _isConnected = false;
      });

      await _connection!.login();

      if (enableMessageCarbons) {
        try {
          await _connection!.enableMessageCarbons();
        } catch (e) {
          _errorsController.add(ErrorResponseEvent(error: 'Carbons failed: $e'));
        }
      }

      // Retrieve offline messages (MAM)
      try {
        final archived = await _connection!.requestArchivedMessages();
        for (final msg in archived) {
          _safeAddArchive(msg);
        }
      } catch (e) {
        _errorsController.add(ErrorResponseEvent(error: 'MAM failed: $e'));
      }

    } catch (e) {
      _errorsController.add(ErrorResponseEvent(error: e.toString()));
      _isConnected = false;
    } finally {
      _isConnecting = false;
    }
  }

  /// Handle connection events
  void _handleConnectionEvent(ConnectionEvent event) async {
    _safeAddConnection(event);

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
      _safeAddError(ErrorResponseEvent(error: e.toString()));
    }
  }

  Future<void> changePresence(String mode) async {
    if (_connection == null || !_isConnected) return;
    try {
      await _connection!.changePresenceType('available', mode);
    } catch (e) {
      _safeAddError(ErrorResponseEvent(error: e.toString()));
    }
  }

  /// Send message with auto-generated ID and timestamp
  Future<void> sendMessage(String to, String body) async {
    if (_connection == null || !_isConnected) {
      _safeAddError(ErrorResponseEvent(error: 'Not connected'));
      return;
    }
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final id = 'msg_$timestamp';
    try {
      await _connection!.sendMessage(to, body, id, timestamp);
    } catch (e) {
      _safeAddError(ErrorResponseEvent(error: e.toString()));
    }
  }

  /// Safe reconnection with retries
  Future<void> _reconnectIfNeeded({int retries = 5}) async {
    int attempt = 0;
    while (!_isConnected && attempt < retries) {
      try {
        attempt++;
        await _connection?.login();
        break;
      } catch (e) {
        _safeAddError(ErrorResponseEvent(error: 'Reconnect attempt $attempt failed: $e'));
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }
  }

  /// Dispose everything safely
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
    await _carbonsController.close();
    await _archiveController.close();
    await _chatStateController.close();
    await _connectionController.close();
    await _presenceController.close();
    await _errorsController.close();
    await _successController.close();

    _isConnected = false;
    _isConnecting = false;
  }

  // --- Safe Stream Add Helpers ---
  void _safeAddMessage(MessageChat m) => _messagesController.isClosed ? null : _messagesController.add(m);
  void _safeAddCarbon(MessageChat m) => _carbonsController.isClosed ? null : _carbonsController.add(m);
  void _safeAddArchive(MessageChat m) => _archiveController.isClosed ? null : _archiveController.add(m);
  void _safeAddChatState(ChatState c) => _chatStateController.isClosed ? null : _chatStateController.add(c);
  void _safeAddConnection(ConnectionEvent e) => _connectionController.isClosed ? null : _connectionController.add(e);
  void _safeAddPresence(PresentModel p) => _presenceController.isClosed ? null : _presenceController.add(p);
  void _safeAddError(ErrorResponseEvent e) => _errorsController.isClosed ? null : _errorsController.add(e);
  void _safeAddSuccess(SuccessResponseEvent e) => _successController.isClosed ? null : _successController.add(e);
}

/// Advanced Listener supporting carbons, MAM, chat states
class XmppListenerAdvanced implements DataChangeEvents {
  final void Function(MessageChat) onMessage;
  final void Function(ConnectionEvent) onConnection;
  final void Function(ErrorResponseEvent) onError;
  final void Function(SuccessResponseEvent) onSuccess;
  final void Function(PresentModel) onPresence;

  final void Function(MessageChat) onCarbonMessage;
  final void Function(MessageChat) onArchivedMessage;
  final void Function(ChatState) onChatState;

  XmppListenerAdvanced({
    required this.onMessage,
    required this.onConnection,
    required this.onError,
    required this.onSuccess,
    required this.onPresence,
    required this.onCarbonMessage,
    required this.onArchivedMessage,
    required this.onChatState,
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
  void onChatStateChange(ChatState c) => onChatState(c);

  // Advanced callbacks
  void onMessageCarbon(MessageChat m) => onCarbonMessage(m);
  void onMessageArchived(MessageChat m) => onArchivedMessage(m);
}
