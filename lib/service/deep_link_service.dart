import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:dhartti/UserScreen/PropertyScreen/PropertyDetailPage.dart';

class DeepLinkService {
  DeepLinkService._();
  static final DeepLinkService instance = DeepLinkService._();

  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  void initialize(GlobalKey<NavigatorState> navKey) {
    _appLinks = AppLinks();

    // Check initial link when app launched from terminated state
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        _handleUri(uri, navKey);
      }
    }).catchError((_) {});

    // Listen to incoming links while app is running / in background
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        _handleUri(uri, navKey);
      },
      onError: (_) {},
    );
  }

  int? _lastHandledId;
  DateTime? _lastHandledTime;

  void _handleUri(Uri uri, GlobalKey<NavigatorState> navKey) {
    // Expected patterns:
    // https://dhartti.com/room-detail/123
    // dhartti://room-detail/123
    final segments = uri.pathSegments;
    int? propertyId;

    if (segments.contains('room-detail')) {
      final index = segments.indexOf('room-detail');
      if (index + 1 < segments.length) {
        propertyId = int.tryParse(segments[index + 1]);
      }
    } else if (uri.host == 'room-detail' && segments.isNotEmpty) {
      propertyId = int.tryParse(segments.first);
    }

    if (propertyId != null) {
      final now = DateTime.now();
      if (_lastHandledId == propertyId &&
          _lastHandledTime != null &&
          now.difference(_lastHandledTime!).inMilliseconds < 1500) {
        return;
      }
      _lastHandledId = propertyId;
      _lastHandledTime = now;

      navKey.currentState?.push(
        MaterialPageRoute(
          settings: RouteSettings(name: '/room-detail/$propertyId'),
          builder: (_) => PropertyDetailPage(propertyId: propertyId!),
        ),
      );
    }
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
