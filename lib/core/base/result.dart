export '../models/result.dart';

// Future 확장 메소드 추가 (이름 충돌 방지)
extension ResultFutureExtensions<T> on Future<T> {
  /// Future 작업의 결과를 Result로 변환
  Future<Result<T>> toResult() async {
    try {
      final data = await this;
      return Result.success(data);
    } catch (e) {
      return Result.failure(e);
    }
  }
}

/// Future<List<T>> 컬렉션에 대한 확장 기능 
extension ResultFutureListExtension<T> on Future<List<T>> {
  /// 비어있는 리스트도 성공으로 처리하는 Result 변환
  Future<Result<List<T>>> toResultCollection() async {
    try {
      final data = await this;
      return Result.success(data);
    } catch (e) {
      return Result.failure(e);
    }
  }
} 