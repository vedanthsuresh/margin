import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service for handling incoming share intents from other apps
/// (Point of Origin Interceptor)
///
/// NOTE: receive_sharing_intent package only handles media files.
/// For text sharing, we use platform channels directly.
class ShareIntentService {
  static final ShareIntentService _instance = ShareIntentService._internal();
  factory ShareIntentService() => _instance;
  ShareIntentService._internal();

  /// Shared text received from other apps
  String? _sharedText;

  /// Callback for when a new share arrives and app is already running
  void Function(String sharedText)? onShareReceived;

  /// Whether the service has been initialized
  bool _initialized = false;

  /// Platform channel for receiving shared text
  static const MethodChannel _channel = MethodChannel('margin/share_intent');

  /// Initialize the share intent service and start listening
  Future<void> initialize() async {
    if (_initialized) return;

    if (kIsWeb) {
      debugPrint('⚠️ ShareIntentService skipped - running on web');
      _initialized = false;
      return;
    }

    try {
      // Listen for subsequent shares while app is running
      _startShareStream();

      // Check for initial intent (app launched via share)
      // Retry with a delay if the first attempt fails (platform channel might not be ready)
      String? initialText;
      try {
        initialText = await _getInitialSharedText();
      } catch (e) {
        debugPrint('⚠️ First attempt to get initial share failed, retrying...: $e');
        // Wait a bit for the platform channel to be ready
        await Future.delayed(const Duration(milliseconds: 500));
        initialText = await _getInitialSharedText();
      }

      if (initialText != null && initialText.isNotEmpty) {
        _sharedText = initialText;
        debugPrint('📥 ShareIntentService: Received initial share: "$initialText"');
      }

      _initialized = true;
      debugPrint('✅ ShareIntentService initialized');
    } catch (e) {
      debugPrint('⚠️ ShareIntentService initialization failed: $e');
      // Still mark as initialized so we can listen for future shares
      _initialized = true;
    }
  }

  /// Get shared text that was passed when the app launched
  Future<String?> _getInitialSharedText() async {
    if (kIsWeb) return null;

    try {
      debugPrint('🔍 ShareIntentService: Calling getInitialText on native side...');
      // Get the initial sharing intent via platform channel
      final result = await _channel.invokeMethod('getInitialText');
      debugPrint('✅ ShareIntentService: Native returned: "$result"');
      return result as String?;
    } catch (e) {
      debugPrint('⚠️ Failed to get initial shared text: $e');
      debugPrint('   This is normal if the app was not opened via share.');
      return null;
    }
  }

  /// Start listening for shares while the app is running
  void _startShareStream() {
    if (kIsWeb) return;

    // Set up method call handler for incoming shares
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onShareReceived') {
        final text = call.arguments as String?;
        if (text != null && text.isNotEmpty) {
          _sharedText = text;
          debugPrint('📥 ShareIntentService: Received share while running: "$text"');

          // Notify callback if set (for navigation)
          onShareReceived?.call(text);
        }
      }
    });
  }

  /// Get the currently stored shared text
  String? getSharedText() {
    return _sharedText;
  }

  /// Check if there is shared text available
  bool hasSharedText() {
    return _sharedText != null && _sharedText!.isNotEmpty;
  }

  /// Clear the shared text after consuming it
  void clearSharedText() {
    if (_sharedText != null) {
      debugPrint('🗑️ ShareIntentService: Cleared shared text');
      _sharedText = null;
    }
  }

  /// Dispose of resources
  void dispose() {
    _channel.setMethodCallHandler(null);
    _initialized = false;
  }
}
