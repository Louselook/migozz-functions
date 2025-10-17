part of 'login_cubit.dart';

class LoginState extends Equatable {
  final bool isLoading;
  final String? email;
  final String? currentOTP;
  final String? errorMessageLogin;
  final String? errorMessageOTP;
  final bool loginSuccess;

  // 🔹 Contador para identificar cada fallo de OTP (un valor único por fallo)
  final int otpErrorCount;

  const LoginState({
    this.isLoading = false,
    this.email,
    this.currentOTP,
    this.errorMessageLogin,
    this.errorMessageOTP,
    this.loginSuccess = false,
    this.otpErrorCount = 0,
  });

  LoginState copyWith({
    bool? isLoading,
    String? email,
    String? currentOTP,
    String? errorMessageLogin,
    String? errorMessageOTP,
    bool? loginSuccess,
    int? otpErrorCount,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      email: email ?? this.email,
      currentOTP: currentOTP ?? this.currentOTP,
      errorMessageLogin: errorMessageLogin ?? this.errorMessageLogin,
      errorMessageOTP: errorMessageOTP ?? this.errorMessageOTP,
      loginSuccess: loginSuccess ?? this.loginSuccess,
      otpErrorCount: otpErrorCount ?? this.otpErrorCount,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    email,
    currentOTP,
    errorMessageLogin,
    errorMessageOTP,
    loginSuccess,
    otpErrorCount,
  ];

  bool get hasError => errorMessageLogin != null || errorMessageOTP != null;
  bool get hasOTP => currentOTP != null && currentOTP!.isNotEmpty;
  bool get hasEmail => email != null && email!.isNotEmpty;
  bool get canProceedToOTP => hasEmail && hasOTP && !isLoading;

  @override
  String toString() {
    return 'LoginState('
        'isLoading: $isLoading, '
        'email: $email, '
        'hasOTP: $hasOTP, '
        'hasError: $hasError, '
        'loginSuccess: $loginSuccess, '
        'otpErrorCount: $otpErrorCount'
        ')';
  }
}
