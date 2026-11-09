import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natter/navigation/natter_history_router.dart';

Route<dynamic> testRoute(Widget page, RouteSettings settings) =>
    MaterialPageRoute<void>(builder: (_) => page, settings: settings);

class TestRouteProvider extends ChangeNotifier
    implements RouteInformationProvider {
  RouteInformation _value = RouteInformation(uri: Uri(path: '/'));
  final List<String> reports = <String>[];

  @override
  RouteInformation get value => _value;

  @override
  void routerReportsNewRouteInformation(
    RouteInformation information, {
    RouteInformationReportingType type = RouteInformationReportingType.none,
  }) {
    _value = information;
    reports.add(information.uri.path);
  }

  void browserNavigateTo(String path) {
    _value = RouteInformation(uri: Uri(path: path));
    notifyListeners();
  }
}

class TestPage extends StatelessWidget {
  const TestPage({super.key, required this.name, this.childName});
  final String name;
  final String? childName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: Center(
        child: Column(
          children: [
            Text(name, key: Key('page-$name')),
            if (childName != null)
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  testRoute(
                    TestPage(name: childName!, childName: null),
                    NatterRouteStore.remember(
                      TestPage(name: childName!, childName: null),
                    ),
                  ),
                ),
                child: const Text('Next'),
              ),
          ],
        ),
      ),
    );
  }
}

void main() {
  test('stale URLs cannot restore old account screens', () async {
    const parser = NatterHistoryRouteParser();
    final initial = await parser.parseRouteInformation(
      RouteInformation(uri: Uri(path: '/natter-screen/no-longer-open')),
    );
    expect(initial, '/');
  });

  for (final userType in <String>['Child', 'Parent']) {
    testWidgets('two browser back gestures navigate two $userType screens',
        (tester) async {
      final provider = TestRouteProvider();
      final delegate = NatterHistoryRouterDelegate(
        initialPage: TestPage(name: '$userType home', childName: 'Profile'),
        routeBuilder: testRoute,
      );
      await tester.pumpWidget(MaterialApp.router(
        routeInformationProvider: provider,
        routeInformationParser: const NatterHistoryRouteParser(),
        routerDelegate: delegate,
      ));
      await tester.pumpAndSettle();

      // Push two real routes using the same imperative API as Natter.
      final navigator = delegate.navigatorKey.currentState!;
      navigator.push(testRoute(
        const TestPage(name: 'Profile'),
        NatterRouteStore.remember(const TestPage(name: 'Profile')),
      ));
      await tester.pumpAndSettle();
      final first = provider.reports.last;
      navigator.push(testRoute(
        const TestPage(name: 'Journey'),
        NatterRouteStore.remember(const TestPage(name: 'Journey')),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('page-Journey')), findsOneWidget);
      provider.browserNavigateTo(first);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('page-Profile')), findsOneWidget);

      provider.browserNavigateTo('/');
      await tester.pumpAndSettle();
      expect(find.byKey(Key('page-$userType home')), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      delegate.dispose();
      provider.dispose();
    });
  }

  testWidgets('browser Forward restores screens after home replacement',
      (tester) async {
    final provider = TestRouteProvider();
    final delegate = NatterHistoryRouterDelegate(
      initialPage: const TestPage(name: 'Startup'),
      routeBuilder: testRoute,
    );
    await tester.pumpWidget(MaterialApp.router(
      routeInformationProvider: provider,
      routeInformationParser: const NatterHistoryRouteParser(),
      routerDelegate: delegate,
    ));
    await tester.pumpAndSettle();

    final navigator = delegate.navigatorKey.currentState!;
    navigator.pushReplacement(testRoute(
      const TestPage(name: 'Chats'),
      NatterRouteStore.remember(const TestPage(name: 'Chats')),
    ));
    await tester.pumpAndSettle();

    final profileSettings =
        NatterRouteStore.remember(const TestPage(name: 'Profile'));
    navigator.push(testRoute(const TestPage(name: 'Profile'), profileSettings));
    await tester.pumpAndSettle();
    final profileUrl = provider.reports.last;

    final journeySettings =
        NatterRouteStore.remember(const TestPage(name: 'Journey'));
    navigator.push(testRoute(const TestPage(name: 'Journey'), journeySettings));
    await tester.pumpAndSettle();
    final journeyUrl = provider.reports.last;

    provider.browserNavigateTo(profileUrl);
    await tester.pumpAndSettle();
    provider.browserNavigateTo('/');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('page-Chats')), findsOneWidget);

    provider.browserNavigateTo(profileUrl);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('page-Profile')), findsOneWidget);

    provider.browserNavigateTo(journeyUrl);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('page-Journey')), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    delegate.dispose();
    provider.dispose();
  });

  testWidgets('replacement of a nested route preserves Forward ancestry',
      (tester) async {
    final provider = TestRouteProvider();
    final delegate = NatterHistoryRouterDelegate(
      initialPage: const TestPage(name: 'Chats'),
      routeBuilder: testRoute,
    );
    await tester.pumpWidget(MaterialApp.router(
      routeInformationProvider: provider,
      routeInformationParser: const NatterHistoryRouteParser(),
      routerDelegate: delegate,
    ));
    await tester.pumpAndSettle();
    final navigator = delegate.navigatorKey.currentState!;
    navigator.push(testRoute(
      const TestPage(name: 'Profile'),
      NatterRouteStore.remember(const TestPage(name: 'Profile')),
    ));
    await tester.pumpAndSettle();

    final next = NatterRouteStore.remember(const TestPage(name: 'Journey'));
    navigator.pushReplacement(testRoute(const TestPage(name: 'Journey'), next));
    await tester.pumpAndSettle();
    final journeyUrl = provider.reports.last;

    provider.browserNavigateTo('/');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('page-Chats')), findsOneWidget);
    provider.browserNavigateTo(journeyUrl);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('page-Journey')), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    delegate.dispose();
    provider.dispose();
  });

}
