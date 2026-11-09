import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Session-local route IDs. URLs contain no child names, message content,
/// Firebase IDs, or other relationship details.
class NatterRouteStore {
  NatterRouteStore._();

  static int _nextId = 0;
  static final Map<String, Widget> _screens = <String, Widget>{};
  static final Map<String, String> _parents = <String, String>{};

  static RouteSettings remember(Widget page) {
    final id = '/natter-screen/${++_nextId}';
    _screens[id] = page;
    return RouteSettings(name: id);
  }

  static Widget? screen(String id) => _screens[id];
  static String? parentOf(String id) => _parents[id];

  static void noteParent(String id, String parentId) {
    if (_screens.containsKey(id)) {
      _parents[id] = parentId;
    }
  }

  static void forgetPreviousSession() {
    _screens.clear();
    _parents.clear();
  }
}

/// Keep the browser URL opaque. An unknown route (including a URL opened
/// after a browser restart) safely falls back to the normal startup router.
class NatterHistoryRouteParser extends RouteInformationParser<String> {
  const NatterHistoryRouteParser();

  @override
  Future<String> parseRouteInformation(RouteInformation information) {
    final path = information.uri.path;
    if (path == '/' ||
        (path.startsWith('/natter-screen/') &&
            NatterRouteStore.screen(path) != null)) {
      return SynchronousFuture<String>(path);
    }
    return SynchronousFuture<String>('/');
  }

  @override
  RouteInformation restoreRouteInformation(String configuration) {
    return RouteInformation(uri: Uri(path: configuration));
  }
}

typedef NatterScreenRouteBuilder =
    Route<dynamic> Function(Widget page, RouteSettings settings);

/// Bridges existing imperative Navigator pushes to Router's multi-entry
/// browser history, shared by every parent and child screen.
class NatterHistoryRouterDelegate extends RouterDelegate<String>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<String> {
  NatterHistoryRouterDelegate({
    required this.initialPage,
    required this.routeBuilder,
  }) {
    _observer = _NatterHistoryObserver(_historyChanged);
  }

  final Widget initialPage;
  final NatterScreenRouteBuilder routeBuilder;

  @override
  final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  late final _NatterHistoryObserver _observer;
  bool _externalNavigation = false;
  bool _scheduled = false;
  bool _disposed = false;

  String get _currentPath {
    final pages = _observer.pages;
    if (pages.length <= 1) return '/';
    return pages.last.settings.name ?? '/';
  }

  @override
  String get currentConfiguration => _currentPath;

  void _historyChanged() {
    if (_externalNavigation || _scheduled || _disposed) return;
    _scheduled = true;
    // Navigator observers can run during a frame; report after the route
    // operation completes so push-and-remove transitions aren't half-read.
    scheduleMicrotask(() {
      _scheduled = false;
      if (!_disposed && !_externalNavigation) notifyListeners();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      observers: <NavigatorObserver>[_observer],
      onGenerateRoute: (settings) => routeBuilder(
        initialPage,
        const RouteSettings(name: '/'),
      ),
    );
  }

  @override
  Future<void> setNewRoutePath(String configuration) async {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    final target = configuration;
    if (target == _currentPath) return;

    _externalNavigation = true;
    try {
      if (target == '/') {
        navigator.popUntil((route) => route.isFirst);
        return;
      }

      final currentPages = _observer.pages;
      if (currentPages.any((route) => route.settings.name == target)) {
        navigator.popUntil((route) => route.settings.name == target);
        return;
      }

      // Restore a forward-history entry only if its screen still belongs
      // to the current in-memory navigation session.
      final missing = <String>[];
      String ancestor = target;
      final visited = <String>{};
      while (ancestor != '/' &&
          !currentPages.any((route) => route.settings.name == ancestor)) {
        if (!visited.add(ancestor) ||
            NatterRouteStore.screen(ancestor) == null) {
          return; // A stale link cannot reopen another child's session.
        }
        missing.add(ancestor);
        ancestor = NatterRouteStore.parentOf(ancestor) ?? '/';
      }

      if (ancestor == '/') {
        navigator.popUntil((route) => route.isFirst);
      } else {
        navigator.popUntil((route) => route.settings.name == ancestor);
      }

      for (final id in missing.reversed) {
        final page = NatterRouteStore.screen(id);
        if (page == null) break;
        navigator.push<dynamic>(routeBuilder(page, RouteSettings(name: id)));
      }
    } finally {
      _externalNavigation = false;
      _historyChanged();
    }
  }

  @override
  Future<bool> popRoute() async {
    final navigator = navigatorKey.currentState;
    if (navigator == null || !navigator.canPop()) return false;
    return navigator.maybePop();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class _NatterHistoryObserver extends NavigatorObserver {
  _NatterHistoryObserver(this.onChanged);

  final VoidCallback onChanged;
  final List<Route<dynamic>> _routes = <Route<dynamic>>[];

  List<Route<dynamic>> get pages =>
      _routes.whereType<PageRoute<dynamic>>().toList(growable: false);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute<dynamic>) {
      final parentId = pages.isEmpty ? '/' : pages.last.settings.name ?? '/';
      final id = route.settings.name;
      if (id != null && id != '/') {
        NatterRouteStore.noteParent(id, parentId);
      }
    }
    _routes.add(route);
    onChanged();
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
    onChanged();
    super.didPop(route, previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
    if (pages.length == 1) {
      NatterRouteStore.forgetPreviousSession();
    }
    onChanged();
    super.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute != null) {
      final index = _routes.indexOf(oldRoute);
      if (index >= 0) {
        if (newRoute == null) {
          _routes.removeAt(index);
        } else {
          _routes[index] = newRoute;
        }
      } else if (newRoute != null) {
        _routes.add(newRoute);
      }
    } else if (newRoute != null) {
      _routes.add(newRoute);
    }
    if (pages.length == 1) {
      NatterRouteStore.forgetPreviousSession();
    }
    onChanged();
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}
