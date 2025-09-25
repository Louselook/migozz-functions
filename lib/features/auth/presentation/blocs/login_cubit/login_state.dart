part of 'login_cubit.dart';

class LoginState extends Equatable {
  final bool isLoading;
  final String? email;
  final String? currentOTP;
  final String? errorMessageLogin;
  final String? errorMessageOTP;

  const LoginState({
    this.isLoading = false,
    this.email,
    this.currentOTP,
    this.errorMessageLogin,
    this.errorMessageOTP,
  });

  LoginState copyWith({
    bool? isLoading,
    String? email,
    String? currentOTP,
    String? errorMessageLogin,
    String? errorMessageOTP,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      email: email ?? this.email,
      currentOTP: currentOTP ?? this.currentOTP,
      errorMessageLogin: errorMessageLogin ?? this.errorMessageLogin,
      errorMessageOTP: errorMessageOTP ?? this.errorMessageOTP,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    email,
    currentOTP,
    errorMessageLogin,
    errorMessageOTP,
  ];
}
