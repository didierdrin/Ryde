import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ryde_rw/components/widgets/button_bar.dart';
import 'package:ryde_rw/components/widgets/color_button.dart';
import 'package:ryde_rw/service/user_service.dart';
import 'package:ryde_rw/service/wallet_transaction_service.dart';
import 'package:ryde_rw/shared/shared_states.dart';
import 'package:ryde_rw/theme/colors.dart';
import 'package:ryde_rw/components/widgets/entry_field.dart'; // Import the TextEntryField
import 'package:ryde_rw/utils/contants.dart';
import 'package:ryde_rw/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class AddMoneyBottomSheet extends ConsumerStatefulWidget {
  const AddMoneyBottomSheet({super.key});
  @override
  AddMoneyBottomSheetState createState() => AddMoneyBottomSheetState();
}

class AddMoneyBottomSheetState extends ConsumerState<AddMoneyBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  String amount = '';
  final TextEditingController _amountController = TextEditingController();

  bool _isLoading = false;

  String? _validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    return null;
  }

  void handlePriceChange(String value, TextEditingController controller) {
    setState(() {
      amount = value.replaceAll(',', '');
    });
    int? val = int.tryParse(amount);
    if (val == null) {
      controller.value = const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: ('').length),
      );
      return;
    }
    final formattedVal = formatPrice(val);
    controller.value = TextEditingValue(
      text: formattedVal,
      selection: TextSelection.collapsed(offset: formattedVal.length),
    );
    _formKey.currentState?.validate();
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = ref.read(userProvider)!;
      // final region = ref.read(regionProvider);
      final code = await UserService.getPaymentCode();
      final ussdCode = code.replaceFirst('amount', amount);
      await WalletTransactionsService.createWalletTransaction({
        'amount': int.parse(amount),
        'currency': 'RWF',
        'type': 'top-up',
        'status': TransactionStatus.pending.name,
        'user': user.id,
        'date': Timestamp.now(),
      });
      final url = Uri(
        scheme: 'tel',
        path: "tel:${Uri.encodeComponent(ussdCode)}",
      );
      if (await canLaunchUrl(url)) {
        print('code can launch');
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        print('can\'t launch');
      }

      if (mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment processing initiated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing payment: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _launchUSSDCode(String phoneNumber, String amount) async {
    final ussdCode = "*182*1*1*$phoneNumber*$amount#";
    final url = "tel:${Uri.encodeComponent(ussdCode)}";
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  bool isValid() {
    if (amount.isEmpty) {
      return false;
    }
    final v = int.parse(amount.replaceAll(',', ''));
    if (v < 500 || v > 4000) {
      return false;
    }
    return !_isLoading && true;
  }

  @override
  Widget build(BuildContext context) {
    // final region = ref.watch(regionProvider);
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: ListView(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        children: [
          Container(
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                // mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  const Text(
                    "Add Money",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  TextFormField(
                    style: TextStyle(fontSize: 13.5),
                    controller: _amountController,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: false,
                      signed: true,
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: 'Enter amount',
                      hintStyle: Theme.of(context).textTheme.bodyMedium!
                          .copyWith(color: Color(0xffb2b2b2), fontSize: 13.5),
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 24),
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(left: 10, right: 7),
                        child: Text(
                          "RWF",
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ),
                      prefixIconConstraints: BoxConstraints(
                        minWidth: 0,
                        minHeight: 0,
                      ),
                    ),
                    onChanged: (val) {
                      handlePriceChange(val, _amountController);
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a price';
                      }
                      final v = int.parse(value.replaceAll(',', ''));
                      if (v < 500 || v > 4000) {
                        return 'Amount must be between 500 and 4,000';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 30),

                  // Proceed to Payment Button
                  BottomBar(
                    isValid: isValid(),
                    onTap: () {
                      if (isValid()) {
                        FocusScope.of(context).unfocus();
                        _processPayment();
                      }
                    },
                    text: 'Proceed to Payment',
                  ),
                  // GestureDetector(
                  //   onTap: _isLoading ? null : _processPayment,
                  //   child: FadedScaleAnimation(
                  //     scaleDuration: const Duration(milliseconds: 600),
                  //     child: _isLoading
                  //         ? const CircularProgressIndicator()
                  //         : ColorButton("Proceed to Payment"),
                  //   ),
                  // ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

