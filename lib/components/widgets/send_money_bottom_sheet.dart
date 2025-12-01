import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ryde_rw/components/widgets/color_button.dart';
import 'package:ryde_rw/components/widgets/entry_field.dart';
import 'package:ryde_rw/shared/shared_states.dart';
import 'package:ryde_rw/theme/colors.dart';

class SendMoneyBottomSheet extends ConsumerStatefulWidget {
  const SendMoneyBottomSheet({super.key});
  @override
  SendMoneyBottomSheetState createState() => SendMoneyBottomSheetState();
}

class SendMoneyBottomSheetState extends ConsumerState<SendMoneyBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _accountNumberController =
      TextEditingController();
  String? _selectedBank;
  bool _isLoading = false;

  final List<String> banks = ['Bank of Kigali', 'Equity', 'I&M', 'Coopedu'];

  String? _validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Amount is required';
    }
    if (double.tryParse(value) == null) {
      return 'Please enter a valid amount';
    }
    if (double.parse(value) <= 0) {
      return 'Amount must be greater than 0';
    }
    return null;
  }

  String? _validateAccountNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Account number is required';
    }
    if (value.length < 8) {
      return 'Account number must be at least 8 digits';
    }
    return null;
  }

  String? _validateBank(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select a bank';
    }
    return null;
  }

  Future<void> _processSendMoney() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = ref.read(userProvider);
      if (user != null) {
        // Add your money transfer logic here
        await Future.delayed(const Duration(seconds: 2)); // Simulated API call

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Money sent successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending money: ${e.toString()}'),
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
    _accountNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      children: [
        Container(
            width: MediaQuery.of(context).size.width,
            height: 450,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      horizontalTitleGap: 0,
                      leading: SizedBox(
                        height: 20,
                        child: Icon(
                          Icons.payments_outlined,
                          color: primaryColor,
                          size: 20,
                        ),
                      ),
                      title: const Padding(
                        padding: EdgeInsets.fromLTRB(15.0, 0, 0, 0),
                        child: Text(
                          "Send Money to Bank",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      subtitle: const Padding(
                        padding: EdgeInsets.fromLTRB(15.0, 0, 0, 0),
                        child: Text("Enter banking details"),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Bank Selection Dropdown
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _selectedBank,
                        validator: _validateBank,
                        decoration: InputDecoration(
                          labelText: 'Select Bank',
                          prefixIcon: Icon(
                            Icons.account_balance,
                            color: primaryColor,
                            size: 20,
                          ),
                          border: const OutlineInputBorder(
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                        ),
                        items: banks.map((String bank) {
                          return DropdownMenuItem(
                            value: bank,
                            child: Text(
                              bank,
                              style: const TextStyle(color: Colors.black),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedBank = newValue;
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Amount Field
                    TextEntryFieldR(
                      controller: _amountController,
                      label: "Amount",
                      hint: "Enter amount",
                      keyboardType: TextInputType.number,
                      validator: _validateAmount,
                      prefixIcon: Icon(
                        Icons.attach_money,
                        color: primaryColor,
                        size: 20,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Account Number Field
                    TextEntryFieldR(
                      controller: _accountNumberController,
                      label: "Account Number",
                      hint: "Enter account number",
                      keyboardType: TextInputType.number,
                      validator: _validateAccountNumber,
                      prefixIcon: Icon(
                        Icons.account_box,
                        color: primaryColor,
                        size: 20,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),

                    const Spacer(),
                    GestureDetector(
                      onTap: _isLoading ? null : _processSendMoney,
                      child:_isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ColorButton("Send Money"),
                      
                    ),
                    const SizedBox(height: 15),
                  ],
                ),
              ),
            ),
          
        ),
      ],
    );
  }
}

