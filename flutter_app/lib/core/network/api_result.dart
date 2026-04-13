class ApiResult<T> {
  const ApiResult.success(this.data)
      : errorMessage = null,
        isSuccess = true;

  const ApiResult.failure(this.errorMessage)
      : data = null,
        isSuccess = false;

  final T? data;
  final String? errorMessage;
  final bool isSuccess;
}
