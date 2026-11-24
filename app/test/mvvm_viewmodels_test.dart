import 'package:flutter_test/flutter_test.dart';
import 'package:kursorqr/models/qr_link.dart';
import 'package:kursorqr/repositories/qr_link_repository.dart';
import 'package:kursorqr/services/qr_render_service.dart';
import 'package:kursorqr/viewmodels/auth_form_viewmodel.dart';
import 'package:kursorqr/viewmodels/dashboard_viewmodel.dart';
import 'package:kursorqr/viewmodels/landing_viewmodel.dart';
import 'package:kursorqr/viewmodels/qr_link_form_viewmodel.dart';

class _FakeQrLinkRepository implements QrLinkRepository {
  int fetchCalls = 0;

  @override
  Future<List<QrLink>> fetchUserLinks(String ownerId) async {
    fetchCalls += 1;
    return const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('QrLinkFormViewModel validation & slug generation', () {
    test('generateRandomSlug produces valid 7-char lowercase slug', () {
      final slug = QrLinkFormViewModel.generateRandomSlug();
      expect(slug.length, 7);
      expect(QrLinkFormViewModel.validateSlug(slug), isNull);
    });

    test('validateSlug accepts 3-48 char slugs and rejects invalid values', () {
      expect(QrLinkFormViewModel.validateSlug('app'), isNull);
      expect(QrLinkFormViewModel.validateSlug('my-app_2026'), isNull);
      expect(QrLinkFormViewModel.validateSlug('a' * 48), isNull);
      expect(QrLinkFormViewModel.validateSlug(''), isNotNull);
      expect(QrLinkFormViewModel.validateSlug('a'), isNotNull);
      expect(QrLinkFormViewModel.validateSlug('ab'), isNotNull);
      expect(QrLinkFormViewModel.validateSlug('a' * 49), isNotNull);
      expect(QrLinkFormViewModel.validateSlug('-leading-dash'), isNotNull);
      expect(QrLinkFormViewModel.validateSlug('has spaces'), isNotNull);
      expect(QrLinkFormViewModel.validateSlug('bad/slash'), isNotNull);
    });

    test('validateRequiredUrl enforces http/https and length', () {
      expect(
        QrLinkFormViewModel.validateRequiredUrl('https://kursorqr.web.app'),
        isNull,
      );
      expect(QrLinkFormViewModel.validateRequiredUrl(''), isNotNull);
      expect(
        QrLinkFormViewModel.validateRequiredUrl('javascript:alert(1)'),
        isNotNull,
      );
    });

    test('validateOptionalStoreUrl allows empty or store schemes', () {
      expect(QrLinkFormViewModel.validateOptionalStoreUrl(''), isNull);
      expect(
        QrLinkFormViewModel.validateOptionalStoreUrl(
          'https://apps.apple.com/app/id123',
        ),
        isNull,
      );
      expect(
        QrLinkFormViewModel.validateOptionalStoreUrl(
          'itms-apps://itunes.apple.com/app/id123',
        ),
        isNull,
      );
      expect(
        QrLinkFormViewModel.validateOptionalStoreUrl(
          'market://details?id=com.example.app',
        ),
        isNull,
      );
      expect(
        QrLinkFormViewModel.validateOptionalStoreUrl('ftp://bad.example.com'),
        isNotNull,
      );
    });
  });

  group('AuthFormViewModel pure validators', () {
    test('validateEmail rejects malformed addresses', () {
      expect(AuthFormViewModel.validateEmail('user@example.com'), isNull);
      expect(AuthFormViewModel.validateEmail(''), isNotNull);
      expect(AuthFormViewModel.validateEmail('invalid'), isNotNull);
      expect(AuthFormViewModel.validateEmail('no-dot@domain'), isNotNull);
    });

    test('validatePassword enforces minimum length on sign-up only', () {
      expect(
        AuthFormViewModel.validatePassword('1234', isSignUp: false),
        isNull,
      );
      expect(
        AuthFormViewModel.validatePassword('1234', isSignUp: true),
        isNotNull,
      );
      expect(
        AuthFormViewModel.validatePassword('123456', isSignUp: true),
        isNull,
      );
      expect(
        AuthFormViewModel.validatePassword('', isSignUp: false),
        isNotNull,
      );
    });
  });

  group('LandingViewModel', () {
    test('initializes with visible GDPR banner and clay sandbox defaults', () {
      final vm = LandingViewModel(renderService: QrRenderService());
      addTearDown(vm.dispose);

      expect(vm.showGdprBanner, isTrue);
      expect(vm.sandboxViewModel.data, LandingViewModel.defaultSandboxUrl);
      expect(vm.sandboxViewModel.design.useGradient, isTrue);

      vm.dismissGdprBanner();
      expect(vm.showGdprBanner, isFalse);
    });
  });

  group('DashboardViewModel refresh cooldown', () {
    test('throttles repeated refreshes within 15 seconds to protect Spark reads',
        () async {
      var now = DateTime(2026, 11, 24, 12, 0, 0);
      final repo = _FakeQrLinkRepository();
      final vm = DashboardViewModel(
        repository: repo,
        ownerId: 'uid-1',
        ownerEmail: 'user@example.com',
        clock: () => now,
      );
      addTearDown(vm.dispose);

      expect(await vm.refresh(), isTrue);
      expect(repo.fetchCalls, 1);
      expect(vm.refreshCooldownRemainingSeconds, 15);
      expect(vm.canRefresh, isFalse);

      now = now.add(const Duration(seconds: 5));
      expect(vm.refreshCooldownRemainingSeconds, 10);
      expect(await vm.refresh(), isFalse);
      expect(repo.fetchCalls, 1);

      now = now.add(const Duration(seconds: 10));
      expect(vm.refreshCooldownRemainingSeconds, 0);
      expect(vm.canRefresh, isTrue);
      expect(await vm.refresh(), isTrue);
      expect(repo.fetchCalls, 2);
    });
  });
}
