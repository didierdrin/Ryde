import 'package:flutter/material.dart';
import 'package:ryde_rw/theme/colors.dart';
import 'package:ryde_rw/theme/style_text.dart';

class BuildListTile extends StatelessWidget {
  final String image;
  final String text;
  final Function? onTap;
  final bool isSelected;
  final IconData? icon;

  const BuildListTile({
    super.key,
    required this.image,
    required this.text,
    this.onTap,
    this.isSelected = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(color: kWhiteColor),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          vertical: 4.0,
          horizontal: 20.0,
        ),
        leading: Container(
          height: 32,
          width: 32,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8.0)),
          child: Icon(
            icon,
            color: isSelected ? const Color(0xFFB90000) : kMainColor,
            size: 20.0,
          ),
        ),
        title: Text(
          text,
          style: AppStyles.accountTextStyle.copyWith(
            color: isSelected
                ? const Color(0xFFB90000)
                : const Color(0xff555555),
          ),
        ),
        onTap: onTap as void Function()?,
      ),
    );
  }
}

