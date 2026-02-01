import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:migozz_app/features/wallet/model/transaction_model.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  const TransactionTile({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      child: Row(
        children: [
          SvgPicture.asset(
            TransactionModel.icons[transaction.type] ?? 'assets/icons/default.svg',
            height: 22,
          ),
          
          const SizedBox(width: 10),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  TransactionModel.titleRender(
                    transaction.type, 
                    transaction.fromName, 
                    transaction.toName
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  softWrap: false,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color.fromARGB(255, 94, 94, 94),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  DateFormat('MMM d, yyyy').format(transaction.created),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color.fromARGB(106, 64, 64, 64),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),
          
          Text(
            TransactionModel.amountRender(transaction.type, transaction.amount),
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: TransactionModel.colorRender(transaction.type),
            ),
          ),
        ],
      ),
    );
  }
}