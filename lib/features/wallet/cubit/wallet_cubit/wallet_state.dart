import 'package:equatable/equatable.dart';
import 'package:migozz_app/features/wallet/model/wallet_model.dart';

// Definimos el semáforo de la Wallet
enum WalletStatus { initial, loading, initialized, error }

class WalletState extends Equatable {
  final WalletStatus status;
  final WalletModel? walletData;
  final String? errorMessage;

  const WalletState({
    required this.status,
    this.walletData,
    this.errorMessage,
  });

  const WalletState.initial()
      : status = WalletStatus.initial,
        walletData = null,
        errorMessage = null;

  const WalletState.loading()
      : status = WalletStatus.loading,
        walletData = null,
        errorMessage = null;

  const WalletState.initialized(WalletModel data)
      : status = WalletStatus.initialized,
        walletData = data,
        errorMessage = null;

  const WalletState.error(String message)
      : status = WalletStatus.error,
        walletData = null,
        errorMessage = message;

  WalletState copyWith({
    WalletStatus? status,
    WalletModel? walletData,
    String? errorMessage,
  }) {
    return WalletState(
      status: status ?? this.status,
      walletData: walletData ?? this.walletData,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get isLoading => status == WalletStatus.loading;
  bool get hasData => status == WalletStatus.initialized && walletData != null;

  @override
  List<Object?> get props => [status, walletData, errorMessage];
}