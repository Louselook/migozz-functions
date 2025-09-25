part of 'login_cubit.dart';

class LoginState extends Equatable {
  final bool isLoading;
  final String? email;
  final String? currentOTP;
  final String? errorMessage;

  const LoginState({
    this.isLoading = false,
    this.email,
    this.currentOTP,
    this.errorMessage,
  });

  LoginState copyWith({
    bool? isLoading,
    String? email,
    String? currentOTP,
    String? errorMessage,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      email: email ?? this.email,
      currentOTP: currentOTP ?? this.currentOTP,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, email, currentOTP, errorMessage];
}
