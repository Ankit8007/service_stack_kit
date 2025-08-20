import 'package:socket_io_client/socket_io_client.dart' as IO;

typedef SocketHandler =
    void Function({
      void Function()? onConnect,
      void Function()? onDisconnect,
      void Function(dynamic error)? onError,
      Function(int)? onReconnectAttempt,
    });

/// SocketService: Singleton-per-URL socket handler.
class SocketService {
  static final Map<String, SocketService> _instances = {};

  final String url;
  final IO.Socket _socket;

  // /// Optional callbacks
  //  void Function()? onConnectCallback;
  //  void Function(dynamic error)? onErrorCallback;
  //  void Function(dynamic reason)? onDisconnectCallback;
  //  void Function(int attempt)? onReconnectAttemptCallback;
  /// Stored callbacks
  void Function()? _onConnectCallback;
  void Function(dynamic error)? _onErrorCallback;
  void Function(dynamic reason)? _onDisconnectCallback;
  void Function(int attempt)? _onReconnectAttemptCallback;

  /// Private constructor
  SocketService._internal(
    this.url, {
    Map<String, dynamic>? queryParams,
    String? authToken,
  }) : _socket = IO.io(
         url,
         IO.OptionBuilder()
             .setTransports(['websocket'])
             .enableAutoConnect()
             .enableReconnection()
             .setQuery({
               if (queryParams != null) ...queryParams,
             }).setExtraHeaders({
           if (authToken != null) 'Authorization': authToken,
         })
             .build(),
       ) {
    _initializeDefaultListeners();
  }

  /// Factory: Return existing or create new instance per URL
  factory SocketService(
    String url, {
    Map<String, dynamic>? queryParams,
    String? authToken,
  }) {
    if (_instances.containsKey(url)) {
      return _instances[url]!;
    }

    final instance = SocketService._internal(
      url,
      queryParams: queryParams,
      authToken: authToken,
    );

    _instances[url] = instance;
    return instance;
  }

  /// Register event handlers
  void handle({
    void Function()? onConnect,
    void Function(dynamic error)? onError,
    void Function(dynamic reason)? onDisconnect,
    void Function(int attempt)? onReconnectAttempt,
  }) {
    _onConnectCallback = onConnect;
    _onErrorCallback = onError;
    _onDisconnectCallback = onDisconnect;
    _onReconnectAttemptCallback = onReconnectAttempt;
  }

  /// Setup default socket listeners
  void _initializeDefaultListeners() {
    _socket.onConnect((_) => _onConnectCallback?.call());
    _socket.onDisconnect((data) => _onDisconnectCallback?.call(data));
    _socket.onError((error) => _onErrorCallback?.call(error));
    _socket.onReconnectAttempt(
      (attempt) => _onReconnectAttemptCallback?.call(attempt),
    );
  }

  // void _initializeDefaultListeners() {
  //   _socket.onConnect((_) {
  //     if (onConnectCallback != null) onConnectCallback!();
  //   });
  //
  //   _socket.onDisconnect((data) {
  //     if (onDisconnectCallback != null) onDisconnectCallback!(data);
  //   });
  //
  //   _socket.onError((error) {
  //     if (onErrorCallback != null) onErrorCallback!(error);
  //   });
  //
  //   _socket.onReconnectAttempt((attempt) {
  //     if (onReconnectAttemptCallback != null)
  //       onReconnectAttemptCallback!(attempt);
  //   });
  // }

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
  void on(String event, Function(dynamic) callback) =>
      hasListeners(event) ? null : _socket.on(event, callback);

  /// Listen to an event only once
  void once(String event, Function(dynamic) callback) =>
      _socket.once(event, callback);

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
  static Map<String, SocketService> get allInstances =>
      Map.unmodifiable(_instances);

  /// Dispose all sockets
  static void disposeAll() {
    _instances.forEach((_, service) => service.dispose());
    _instances.clear();
  }
}
