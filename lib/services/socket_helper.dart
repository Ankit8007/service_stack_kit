import 'package:socket_io_client/socket_io_client.dart' as IO;

/// SocketService: Singleton-per-URL socket handler.
class SocketService {
  static final Map<String, SocketService> _instances = {};

  final String url;
  final IO.Socket _socket;

  /// Optional callbacks
  final void Function()? onConnectCallback;
  final void Function(dynamic error)? onErrorCallback;
  final void Function(dynamic reason)? onDisconnectCallback;
  final void Function(int attempt)? onReconnectAttemptCallback;

  /// Private constructor
  SocketService._internal(
      this.url, {
        Map<String, dynamic>? queryParams,
        this.onConnectCallback,
        this.onErrorCallback,
        this.onDisconnectCallback,
        this.onReconnectAttemptCallback,
      }) : _socket = IO.io(
    url,
    IO.OptionBuilder()
        .setTransports(['websocket'])
        .setQuery(queryParams ?? {})
        .enableAutoConnect()
        .enableReconnection()
        .build(),
  ) {
    _initializeDefaultListeners();
  }

  /// Factory: Return existing or create new instance per URL
  factory SocketService(
      String url, {
        Map<String, dynamic>? queryParams,
        void Function()? onConnect,
        void Function(dynamic error)? onError,
        void Function(dynamic reason)? onDisconnect,
        void Function(int attempt)? onReconnectAttempt,
      }) {
    if (_instances.containsKey(url)) {
      return _instances[url]!;
    }

    final instance = SocketService._internal(
      url,
      queryParams: queryParams,
      onConnectCallback: onConnect,
      onErrorCallback: onError,
      onDisconnectCallback: onDisconnect,
      onReconnectAttemptCallback: onReconnectAttempt,
    );

    _instances[url] = instance;
    return instance;
  }

  /// Setup default socket listeners
  void _initializeDefaultListeners() {
    _socket.onConnect((_) {
      if (onConnectCallback != null) onConnectCallback!();
    });

    _socket.onDisconnect((data) {
      if (onDisconnectCallback != null) onDisconnectCallback!(data);
    });

    _socket.onError((error) {
      if (onErrorCallback != null) onErrorCallback!(error);
    });

    _socket.onReconnectAttempt((attempt) {
      if (onReconnectAttemptCallback != null) onReconnectAttemptCallback!(attempt);
    });
  }

  /// Connect the socket
  void connect() {
    if (!_socket.connected) {
      _socket.connect();
    }
  }

  /// Disconnect the socket (but keep instance)
  void disconnect({bool removeListeners = false}) {
    _socket.disconnect();
    if (removeListeners) _socket.clearListeners();
  }

  /// Completely dispose socket and remove instance
  void dispose() {
    _socket.dispose();
    _instances.remove(url);
  }

  /// Emit an event with data
  void emit(String event, dynamic data) => _socket.emit(event, data);

  /// Listen to an event
  void on(String event, Function(dynamic) callback) => _socket.on(event, callback);

  /// Listen to an event only once
  void once(String event, Function(dynamic) callback) => _socket.once(event, callback);

  /// Remove a listener
  void off(String event) => _socket.off(event);

  /// Remove all listeners for the socket
  void offAll() => _socket.clearListeners();

  /// Reconnect manually
  void reconnect() {
    _socket.disconnect();
    _socket.connect();
  }

  /// Check connection state
  bool get isConnected => _socket.connected;

  // /// Check if the socket is currently connecting
  // // bool get isConnecting => _socket.io.engine?.connecting ?? false;
  // bool get isConnecting => _socket.io.engine?.;

  /// Check if the socket has listeners for an event
  bool hasListeners(String event) => _socket.hasListeners(event);

  /// Get the underlying socket
  IO.Socket get raw => _socket;

  /// Get all existing instances (for debugging or cleanup)
  static Map<String, SocketService> get allInstances => Map.unmodifiable(_instances);

  /// Dispose all sockets
  static void disposeAll() {
    _instances.forEach((_, service) => service.dispose());
    _instances.clear();
  }
}
