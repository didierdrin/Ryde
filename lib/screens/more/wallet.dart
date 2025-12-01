import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:ryde_rw/shared/shared_states.dart';

import 'package:ryde_rw/theme/colors.dart';
import 'package:animation_wrappers/Animations/faded_scale_animation.dart';
import 'package:animation_wrappers/Animations/faded_slide_animation.dart';
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
    // final region = ref.watch(regionProvider);

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
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 25),
                    Text(
                      "${"RWF"} ${formatPrice(totalBalance)}",
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge!.copyWith(fontSize: 22),
                    ),
                    SizedBox(width: 20),
                    Text(
                      "Available balance",
                      //  locale.availableBalance!,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium!.copyWith(fontSize: 15),
                    ),
                  ],
                ),
                SizedBox(width: 40),
                Expanded(
                  child: FadedScaleAnimation(
                    scaleDuration: const Duration(milliseconds: 600),
                    child: Image.asset(
                      "assets/img_verification.png",
                      height: 130,
                      alignment: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FadedSlideAnimation(
              beginOffset: Offset(0, 0.4),
              endOffset: Offset(0, 0),
              slideCurve: Curves.linearToEaseOut,
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Spacer(),
                          GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                ),
                                builder: (context) =>
                                    AddMoneyBottomSheet(), // Create this as a separate widget
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 15,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.arrow_downward,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 20),
                                  SizedBox(
                                    width: 85,
                                    child: Text(
                                      "Add Money",
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge!
                                          .copyWith(
                                            color: Colors.white,
                                            fontSize: 13.5,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Spacer(),
                          VerticalDivider(
                            color: Colors.white,
                            indent: 4,
                            endIndent: 4,
                          ),
                          Spacer(),
                          GestureDetector(
                            onTap: () {
                              // showModalBottomSheet(
                              //   context: context,
                              //   isScrollControlled: true,
                              //   shape: RoundedRectangleBorder(
                              //     borderRadius: BorderRadius.vertical(
                              //       top: Radius.circular(20),
                              //     ),
                              //   ),
                              //   builder: (context) =>
                              //       SendMoneyBottomSheet(), // Create this as a separate widget
                              // );
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 15,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.arrow_upward,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 20),
                                  SizedBox(
                                    width: 85,
                                    child: Text(
                                      "Send Money",
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge!
                                          .copyWith(
                                            color: Colors.white,
                                            fontSize: 13.5,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Spacer(),
                        ],
                      ),
                    ),
                  ),
                  transactions.isNotEmpty
                      ? Expanded(
                          child: Container(
                            color: Theme.of(context).primaryColor,
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

                                  // Convert Firestore timestamp to DateTime

                                  // Format DateTime to a readable format
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
                          ),
                        )
                      : Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(height: 30),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
