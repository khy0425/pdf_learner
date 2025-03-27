/// 작업 결과를 표현하는 제네릭 클래스
///
/// 성공 또는 실패 상태와 데이터를 담고 있습니다.
class Result<T> {
  final T? _data;
  final dynamic _error;
  final bool _isSuccess;

  /// 성공 상태의 결과를 생성합니다.
  Result.success(T data)
      : _data = data,
        _error = null,
        _isSuccess = true;

  /// 실패 상태의 결과를 생성합니다.
  Result.failure(dynamic error)
      : _data = null,
        _error = error,
        _isSuccess = false;

  /// 작업이 성공했는지 여부
  bool get isSuccess => _isSuccess;

  /// 작업이 실패했는지 여부
  bool get isFailure => !_isSuccess;

  /// 데이터를 가져옵니다. 실패 상태인 경우 null을 반환합니다.
  T? getOrNull() => _data;

  /// 오류 정보를 가져옵니다. 성공 상태인 경우 null을 반환합니다.
  dynamic get error => _error;

  /// 데이터를 가져오거나 기본값을 반환합니다.
  T getOrDefault(T defaultValue) => _data ?? defaultValue;

  /// 데이터를 가져오거나 오류 발생 시 콜백 함수를 실행합니다.
  T getOrElse(T Function(dynamic error) onError) {
    if (_isSuccess) return _data as T;
    return onError(_error);
  }

  /// 데이터를 변환하여 새로운 Result 객체를 생성합니다.
  Result<R> map<R>(R Function(T data) transform) {
    if (_isSuccess) return Result.success(transform(_data as T));
    return Result.failure(_error);
  }

  /// 콜백 함수를 실행하여 새로운 Result 객체를 생성합니다.
  Result<R> flatMap<R>(Result<R> Function(T data) transform) {
    if (_isSuccess) return transform(_data as T);
    return Result.failure(_error);
  }

  /// 성공 시 콜백 함수를 실행합니다.
  Result<T> onSuccess(void Function(T data) action) {
    if (_isSuccess) action(_data as T);
    return this;
  }

  /// 실패 시 콜백 함수를 실행합니다.
  Result<T> onFailure(void Function(dynamic error) action) {
    if (!_isSuccess) action(_error);
    return this;
  }

  /// 결과를 처리하는 함수를 실행합니다.
  R fold<R>(R Function(T data) onSuccess, R Function(dynamic error) onFailure) {
    if (_isSuccess) return onSuccess(_data as T);
    return onFailure(_error);
  }

  @override
  String toString() {
    if (_isSuccess) return 'Success: $_data';
    return 'Failure: $_error';
  }
} 