import '../models/result.dart' as models;

/// 비동기 작업의 결과를 나타내는 추상 클래스
/// 
/// models/result.dart에 정의된 Result 클래스와 호환됩니다.
/// 그러나 이 클래스는 추상 클래스로 Success와 Failure 서브클래스를 통해 구현됩니다.
abstract class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  Exception? get error => isFailure ? (this as Failure<T>).error : null;
  String? get message => isFailure ? (this as Failure<T>).error.toString() : null;
  T? get data => isSuccess ? (this as Success<T>).data : null;

  /// models/result.dart와의 호환성을 위한 getOrNull 메서드
  T? getOrNull() {
    if (isSuccess) {
      return (this as Success<T>).data;
    } else {
      return null;
    }
  }
  
  /// models/result.dart와의 호환성을 위한 getOrDefault 메서드
  T getOrElse(T defaultValue) => isSuccess ? (this as Success<T>).data : defaultValue;
  
  /// models/result.dart와의 호환성을 위한 getOrThrow 메서드
  T getOrThrow() {
    if (isSuccess) {
      return (this as Success<T>).data;
    } else {
      throw (this as Failure<T>).error;
    }
  }

  /// 조건부 처리를 위한 when 메서드
  R when<R>({
    required R Function(T data) success,
    required R Function(Exception error) failure,
  }) {
    if (isSuccess) {
      return success((this as Success<T>).data);
    } else {
      return failure((this as Failure<T>).error);
    }
  }

  /// models/result.dart와의 호환성을 위한 map 메서드
  Result<R> map<R>(R Function(T data) transform) {
    if (isSuccess) {
      return Success<R>(transform((this as Success<T>).data));
    } else {
      return Failure<R>((this as Failure<T>).error);
    }
  }

  /// models/result.dart와의 호환성을 위한 onSuccess 메서드
  Result<T> onSuccess(void Function(T data) action) {
    if (isSuccess) {
      action((this as Success<T>).data);
    }
    return this;
  }

  /// models/result.dart와의 호환성을 위한 onFailure 메서드
  Result<T> onFailure(void Function(dynamic error) action) {
    if (isFailure) {
      action((this as Failure<T>).error);
    }
    return this;
  }

  /// models/result.dart와의 호환성을 위한 fold 메서드
  R fold<R>(R Function(T data) onSuccess, R Function(dynamic error) onFailure) {
    if (isSuccess) {
      return onSuccess((this as Success<T>).data);
    } else {
      return onFailure((this as Failure<T>).error);
    }
  }

  /// models/result.dart와의 호환성을 위한 정적 팩토리 메서드
  static Result<T> success<T>(T data) => Success<T>(data);
  static Result<T> failure<T>(dynamic error) {
    final exception = error is Exception 
        ? error 
        : Exception(error.toString());
    return Failure<T>(exception);
  }

  /// models/result.dart 타입으로 변환
  models.Result<T> toModelsResult() {
    if (isSuccess) {
      return models.Result.success((this as Success<T>).data);
    } else {
      return models.Result.failure((this as Failure<T>).error);
    }
  }

  /// models/result.dart 타입에서 변환
  static Result<T> fromModelsResult<T>(models.Result<T> result) {
    if (result.isSuccess) {
      return Success<T>(result.getOrThrow());
    } else {
      return Failure<T>(Exception(result.error));
    }
  }
  
  /// JSON Map에서 Result 객체 생성
  static Result<T> fromMap<T>(Map<String, dynamic> map, T Function(Map<String, dynamic>) fromJson) {
    try {
      final isSuccess = map['isSuccess'] as bool;
      if (isSuccess) {
        final data = fromJson(map['data']);
        return Success<T>(data);
      } else {
        final errorMessage = map['error'] as String?;
        return Failure<T>(Exception(errorMessage ?? 'Unknown error'));
      }
    } catch (e) {
      return Failure<T>(Exception('Failed to parse result: $e'));
    }
  }
  
  /// Result 객체를 JSON Map으로 변환
  Map<String, dynamic> toMap(Map<String, dynamic> Function(T) toJson) {
    if (isSuccess) {
      return {
        'isSuccess': true,
        'data': toJson((this as Success<T>).data),
        'error': null,
      };
    } else {
      return {
        'isSuccess': false,
        'data': null,
        'error': (this as Failure<T>).error.toString(),
      };
    }
  }
  
  @override
  String toString() {
    if (isSuccess) {
      return 'Success(${(this as Success<T>).data})';
    } else {
      return 'Failure(${(this as Failure<T>).error})';
    }
  }
}

/// 성공을 나타내는 Result 구현
class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Success<T> && data == other.data;
  }
  
  @override
  int get hashCode => data.hashCode;
}

/// 실패를 나타내는 Result 구현
class Failure<T> extends Result<T> {
  final Exception error;
  const Failure(this.error);
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Failure<T> && error.toString() == other.error.toString();
  }
  
  @override
  int get hashCode => error.hashCode;
}

extension FutureResultX<T> on Future<Result<T>> {
  Future<T?> getOrNull() async => (await this).getOrNull();
  Future<T> getOrElse(T defaultValue) async => (await this).getOrElse(defaultValue);
  Future<T> getOrThrow() async => (await this).getOrThrow();
  
  Future<Result<R>> map<R>(R Function(T data) transform) async {
    final result = await this;
    return result.map(transform);
  }
  
  Future<Result<T>> onSuccess(void Function(T data) action) async {
    final result = await this;
    return result.onSuccess(action);
  }
  
  Future<Result<T>> onFailure(void Function(dynamic error) action) async {
    final result = await this;
    return result.onFailure(action);
  }
}

extension ObjectX<T> on T {
  Result<T> toResult() => Result.success(this);
}

extension NullableObjectX<T> on T? {
  Result<T> toResultOr(dynamic error) {
    return this != null ? Result.success(this as T) : Result.failure(error);
  }
} 