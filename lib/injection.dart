// 이 파일은 의존성 주입을 core/di/dependency_injection.dart로 리다이렉트합니다.
// 하위 호환성을 위해 유지되고 있습니다.
export 'core/di/dependency_injection.dart';

// 기존 코드에서 사용되는 getIt과 configureDependencies에 대한 호환성 지원
import 'package:get_it/get_it.dart';
import 'core/di/dependency_injection.dart' as di;
import 'package:shared_preferences/shared_preferences.dart';
import 'presentation/viewmodels/auth_viewmodel.dart';
import 'presentation/viewmodels/pdf_viewmodel.dart';
import 'presentation/viewmodels/locale_viewmodel.dart';
import 'presentation/viewmodels/theme_viewmodel.dart';
import 'presentation/viewmodels/pdf_file_viewmodel.dart';
import 'services/auth/auth_service.dart';
import 'services/payment/payment_service.dart';
import 'services/payment/paypal_payment_provider.dart';
import 'repositories/pdf_repository.dart';
import 'services/pdf/pdf_service.dart';

/// GetIt 인스턴스에 대한 간편한 액세스
final GetIt getIt = di.DependencyInjection.instance;

/// 의존성 주입 초기화 (하위 호환성을 위해 유지됨)
Future<void> configureDependencies() async {
  await di.DependencyInjection.init();
} 