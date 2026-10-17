/// Domain-level error abstraction shared by every repository.
/// Local and remote data sources map their exceptions to these.
sealed class Failure {
  const Failure(this.message);
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

final class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Local storage error']);
}

final class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error']);
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

final class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Something went wrong']);
}
