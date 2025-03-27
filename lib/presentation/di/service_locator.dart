import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:pdf_learner_v2/services/firebase_service.dart';
import 'package:pdf_learner_v2/domain/repositories/auth_repository.dart';
import 'package:pdf_learner_v2/data/repositories/auth_repository_impl.dart';
import 'package:pdf_learner_v2/domain/repositories/pdf_repository.dart';
import 'package:pdf_learner_v2/data/repositories/pdf_repository_impl.dart';
import 'package:pdf_learner_v2/presentation/viewmodels/auth_viewmodel.dart';
import 'package:pdf_learner_v2/presentation/viewmodels/pdf_viewmodel.dart';

/// 서비스 로케이터 인스턴스
final GetIt getIt = GetIt.instance;

Future<void> setupLocator() async {
  // 서드파티 서비스 등록
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
  
  getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  getIt.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  getIt.registerLazySingleton<FirebaseStorage>(() => FirebaseStorage.instance);
  getIt.registerLazySingleton<GoogleSignIn>(() => GoogleSignIn());
  
  // 서비스 등록
  getIt.registerLazySingleton<FirebaseService>(
    () => FirebaseService(
      getIt<FirebaseAuth>(),
      getIt<FirebaseFirestore>(),
      getIt<FirebaseStorage>(),
    ),
  );
  
  // 리포지토리 등록
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      getIt<FirebaseService>(),
      getIt<GoogleSignIn>(),
    ),
  );
  
  getIt.registerLazySingleton<PDFRepository>(
    () => PDFRepositoryImpl(
      getIt<FirebaseService>(),
      getIt<SharedPreferences>(),
    ),
  );
  
  // 뷰모델 등록
  getIt.registerFactory<AuthViewModel>(
    () => AuthViewModel(
      getIt<AuthRepository>(),
    ),
  );
  
  getIt.registerFactory<PDFViewModel>(
    () => PDFViewModel(
      getIt<PDFRepository>(),
    ),
  );
}

Future<void> resetDependencies() async {
  await getIt.reset();
  await setupLocator();
} 