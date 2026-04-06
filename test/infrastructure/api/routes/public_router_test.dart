import 'package:mocktail/mocktail.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:test/test.dart';

import 'package:sambura_core/infrastructure/barrel.dart';

class MockPackageManagerRouter extends Mock implements PackageManagerRouter {}

class MockAuthController extends Mock implements AuthController {}

class MockSystemController extends Mock implements SystemController {}

void main() {
  setUpAll(() {
    registerFallbackValue(Request('GET', Uri.parse('http://localhost/')));
  });

  test(
    'PublicRouter exposes /npm route directly and legacy /packages/npm works',
    () async {
      final packageManagerRouter = MockPackageManagerRouter();
      final pmRouter = Router();
      pmRouter.get('/npm/<repo>/<package|.*>', (
        Request request,
        String repo,
        String package,
      ) {
        return Response.ok('OK');
      });

      when(() => packageManagerRouter.router).thenReturn(pmRouter);

      final mockAuthController = MockAuthController();
      final mockPackageManagerRouter = MockPackageManagerRouter();
      final mockSystemController = MockSystemController();

      when(
        () => mockSystemController.router,
      ).thenReturn(Router()..get('/health', (_) => Response.ok('healthy')));

      final publicRouter = PublicRouter(
        mockPackageManagerRouter,
        mockAuthController,
        mockSystemController,
      );

      final handler = publicRouter.router;

      final response = await handler.call(
        Request('GET', Uri.parse('http://localhost/npm/public/express')),
      );
      expect(response.statusCode, equals(200));

      final responseLegacy = await handler.call(
        Request('GET', Uri.parse('http://localhost/npm/public/express')),
      );
      expect(responseLegacy.statusCode, equals(200));
    },
  );
}
