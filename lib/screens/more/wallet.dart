import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:ryde_rw/shared/shared_states.dart';

import 'package:ryde_rw/theme/colors.dart';
// Flutter riverpod related imports
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ryde_rw/service/wallet_transaction_service.dart';
import 'package:ryde_rw/components/widgets/add_money_bottom_sheet.dart';
import 'package:ryde_rw/utils/utils.dart';

class Wallet extends ConsumerWidget {
  const Wallet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider)!;
    final transactionsStream = ref.watch(
      WalletTransactionsService.myTransactions,
    );
    final transactions = transactionsStream.value ?? [];
    final totalBalance = user.walletBalance;

    transactions.sort((a, b) => b.date.compareTo(a.date));

    bool isDebit(String type) {
      return ['payment', 'top-up'].contains(type);
    }

    return Scaffold(
      appBar: AppBar(elevation: 0, backgroundColor: backgroundColor),
      body: Column(
        children: [
          Container(
            color: backgroundColor,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "RWF ${formatPrice(totalBalance)}",
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge!.copyWith(fontSize: 22),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Available balance",
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium!.copyWith(fontSize: 15),
                    ),
                  ],
                ),
                Spacer(),
                GestureDetector(
                  onTap: () {
                    // Handle send money action
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.arrow_upward,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Send Money",
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          transactions.isNotEmpty
              ? Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.only(top: 10, bottom: 30),
                      shrinkWrap: true,
                      itemCount: transactions.length,
                      itemBuilder: (BuildContext context, int index) {
                        final transaction = transactions[index];
                        final isDebitTrans = isDebit(
                          transaction.type,
                        );

                        String formattedDate = DateFormat(
                          'dd MMM, hh:mm a',
                        ).format(transaction.date);

                        return ListTile(
                          title: Row(
                            children: [
                              Text(
                                '${transaction.type[0].toUpperCase()}${transaction.type.substring(1)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge!
                                    .copyWith(fontSize: 13.5),
                              ),
                              Spacer(),
                              Text(
                                "${isDebitTrans ? '' : '-'} ${formatPrice(transaction.amount)} ${transaction.currency}",
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge!
                                    .copyWith(
                                      color: isDebitTrans
                                          ? primaryColor
                                          : kRed,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.5,
                                    ),
                              ),
                            ],
                          ),
                          subtitle: Row(
                            children: [
                              Text(
                                '${transaction.status[0].toUpperCase()}${transaction.status.substring(1)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(
                                      fontSize: 11,
                                      color: Color(0xffb3b3b3),
                                    ),
                              ),
                              Spacer(),
                              Text(
                                formattedDate,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(
                                      fontSize: 11,
                                      color: Color(0xffb3b3b3),
                                    ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                )
              : Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "No transactions yet",
                            style: Theme.of(
                              context,
                            ).textTheme.bodyLarge!.copyWith(fontSize: 20),
                          ),
                          SizedBox(height: 10),
                          Text(
                            "All your transactions will appear here",
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}