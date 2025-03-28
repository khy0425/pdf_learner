import '../exceptions/auth_exception.dart';
import 'exception_wrapper.dart';

/// 작업 결과를 나타내는 제네릭 클래스
/// 
/// 성공 또는 실패 상태를 가지며, 각 상태에 따른 데이터 또는 오류를 포함합니다.
class Result<T> {
  /// 성공 데이터
  final T? _data;
  
  /// 오류 정보
  final Exception? _error;
  
  /// 성공 여부
  final bool isSuccess;
  
  /// 내부 생성자
  const Result.success(T data)
      : _data = data,
        _error = null,
        isSuccess = true;
  
  /// 실패 생성자
  const Result.failure(Exception error)
      : _data = null,
        _error = error,
        isSuccess = false;
  
  /// 문자열로부터 실패 결과 생성
  static Result<T> failureFromString<T>(String message) {
    return Result<T>.failure(ExceptionWrapper.fromString(message));
  }
  
  /// 오류로부터 실패 결과 생성
  static Result<T> failureFromError<T>(dynamic error, [String? message]) {
    if (error is Exception) {
      if (message != null) {
        return Result<T>.failure(
          ExceptionWrapper(message, originalException: error)
        );
      }
      return Result<T>.failure(error);
    }
    
    return Result<T>.failure(
      ExceptionWrapper(message ?? error.toString(), originalException: error)
    );
  }
  
  /// 실패 여부
  bool get isFailure => !isSuccess;
  
  /// 성공 데이터 접근
  T get data {
    if (isSuccess && _data != null) {
      return _data!;
    }
    throw StateError('데이터에 접근하려면 Result가 성공이어야 합니다');
  }
  
  /// 데이터를 안전하게 가져오기(실패 시 null 반환)
  T? get dataOrNull => _data;
  
  /// 오류 접근
  Exception get error {
    if (isFailure && _error != null) {
      return _error!;
    }
    throw StateError('오류에 접근하려면 Result가 실패여야 합니다');
  }
  
  /// 오류를 안전하게 가져오기(성공 시 null 반환)
  Exception? get errorOrNull => _error;
  
  /// 조건부 실행
  R when<R>({
    required R Function(T) success,
    required R Function(Exception) failure,
  }) {
    if (isSuccess) {
      return success(data);
    } else {
      return failure(error);
    }
  }

  /// 조건부 실행 (성공 시에만)
  Result<R> map<R>(R Function(T) mapper) {
    if (isSuccess) {
      try {
        return Result.success(mapper(_data as T));
      } catch (e) {
        return Result.failure(Exception('매핑 오류: $e'));
      }
    } else {
      return Result.failure(_error!);
    }
  }

  /// 비동기 조건부 실행 (성공 시에만)
  Future<Result<R>> asyncMap<R>(Future<R> Function(T) mapper) async {
    if (isSuccess) {
      try {
        final result = await mapper(_data as T);
        return Result.success(result);
      } catch (e) {
        return Result.failure(Exception('비동기 매핑 오류: $e'));
      }
    } else {
      return Result.failure(_error!);
    }
  }

  /// Result를 다른 Result로 변환 (성공 시에만)
  Result<R> flatMap<R>(Result<R> Function(T) mapper) {
    if (isSuccess) {
      try {
        return mapper(_data as T);
      } catch (e) {
        return Result.failure(Exception('플랫 매핑 오류: $e'));
      }
    } else {
      return Result.failure(_error!);
    }
  }

  /// 비동기 Result를 다른 Result로 변환 (성공 시에만)
  Future<Result<R>> asyncFlatMap<R>(Future<Result<R>> Function(T) mapper) async {
    if (isSuccess) {
      try {
        return await mapper(_data as T);
      } catch (e) {
        return Result.failure(Exception('비동기 플랫 매핑 오류: $e'));
      }
    } else {
      return Result.failure(_error!);
    }
  }
  
  /// 데이터 또는 null 반환
  T? getOrNull() => data;
  
  /// 데이터 또는 기본값 반환
  T getOrDefault(T defaultValue) => data ?? defaultValue;
  
  /// 데이터 또는 생성 함수 결과 반환
  T getOrElse(T Function() orElse) => data ?? orElse();
  
  /// 성공 여부에 따라 콜백 실행
  void fold({
    Function(T? data)? onSuccess,
    Function(Exception error)? onFailure,
  }) {
    if (isSuccess && onSuccess != null) {
      onSuccess(_data);
    } else if (isFailure && onFailure != null) {
      onFailure(_error!);
    }
  }
  
  @override
  String toString() {
    return isSuccess
        ? 'Success: ${_data.toString()}'
        : 'Failure: ${_error.toString()}';
  }
}

/// Future<T>를 Future<Result<T>>로 변환하는 확장
extension FutureResultExtension<T> on Future<T> {
  /// Future<T>를 Future<Result<T>>로 변환
  Future<Result<T>> toResult() async {
    try {
      final data = await this;
      return Result.success(data);
    } catch (e) {
      return Result.failure(e is Exception ? e : Exception(e.toString()));
    }
  }
}

/// Future<List<T>>를 Future<Result<List<T>>>로 변환하는 확장
extension FutureListResultExtension<T> on Future<List<T>> {
  /// Future<List<T>>를 Future<Result<List<T>>>로 변환
  Future<Result<List<T>>> toResult() async {
    try {
      final data = await this;
      return Result.success(data);
    } catch (e) {
      return Result.failure(e is Exception ? e : Exception(e.toString()));
    }
  }
} 