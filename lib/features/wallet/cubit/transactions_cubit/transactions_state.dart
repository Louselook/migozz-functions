import 'package:equatable/equatable.dart';
import 'package:migozz_app/features/wallet/model/transaction_model.dart';

// Definimos el semáforo de la Wallet
enum TransactionsStatus { initial, loading, initialized, error }

class TransactionsState extends Equatable {
  final TransactionsStatus status;
  final List<TransactionModel>? transactions;
  final String? errorMessage;

  const TransactionsState({
    required this.status,
    required this.transactions,
    this.errorMessage,
  });

  const TransactionsState.initial()
      : status = TransactionsStatus.initial,
        transactions = null,
        errorMessage = null;

  const TransactionsState.loading()
      : status = TransactionsStatus.loading,
        transactions = null,
        errorMessage = null;

  const TransactionsState.initialized(List<TransactionModel> data)
      : status = TransactionsStatus.initialized,
        transactions = data,
        errorMessage = null;

  const TransactionsState.error(String message)
      : status = TransactionsStatus.error,
        transactions = null,
        errorMessage = message;

  TransactionsState copyWith({
    TransactionsStatus? status,
    List<TransactionModel>? transactions,
    String? errorMessage,
  }) {
    return TransactionsState(
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get isLoading => status == TransactionsStatus.loading;
  bool get hasData => status == TransactionsStatus.initialized && transactions != null;

  @override
  List<Object?> get props => [status, transactions, errorMessage];
}