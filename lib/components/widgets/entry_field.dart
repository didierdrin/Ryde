import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ryde_rw/theme/colors.dart';

class TextEntryField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? image;
  final String? initialValue;
  final bool? readOnly;
  final TextInputType? keyboardType;
  final int? maxLength;
  final int? maxLines;
  final String? hint;
  final InputBorder? border;
  final Widget? prefix;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final Function? onTap;
  final FormFieldValidator<String>? validator;
  final TextCapitalization? textCapitalization;
  final List<TextInputFormatter>? inputFormatters;

  const TextEntryField({
    super.key,
    this.controller,
    this.label,
    this.image,
    this.initialValue,
    this.readOnly,
    this.keyboardType,
    this.maxLength,
    this.hint,
    this.border,
    this.prefix,
    this.maxLines,
    this.suffixIcon,
    this.onTap,
    this.textCapitalization,
    this.prefixIcon,
    this.validator,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
      child: Column(
        children: [
          TextFormField(
            textCapitalization:
                textCapitalization ?? TextCapitalization.sentences,
            cursorColor: primaryColor,
            onTap: onTap as void Function()?,
            autofocus: false,
            controller: controller,
            initialValue: initialValue,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge!.copyWith(fontSize: 13.5),
            inputFormatters: inputFormatters,
            readOnly: readOnly ?? false,
            keyboardType: keyboardType,
            minLines: 1,
            maxLength: maxLength,
            maxLines: maxLines,
            validator: validator,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.only(top: 15),
              prefix: prefix,
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon,
              labelText: label,
              hintText: hint,
              hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: Color(0xffb2b2b2),
                fontSize: 13.5,
              ),
              border:
                  border ??
                  UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
              enabledBorder:
                  border ??
                  UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
              focusedBorder:
                  border ??
                  UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
              counter: Offstage(),
              icon: (image != null)
                  ? ImageIcon(
                      AssetImage(image!),
                      color: primaryColor,
                      size: 20.0,
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class TextEntryFieldR extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? image;
  final bool? readOnly;
  final TextInputType? keyboardType;
  final int? maxLength;
  final int? maxLines;
  final String? hint;
  final InputBorder? border;
  final Widget? prefix;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final Function? onTap;
  final FormFieldValidator<String>? validator;
  final TextCapitalization? textCapitalization;

  const TextEntryFieldR({
    super.key,
    this.controller,
    this.label,
    this.image,
    this.readOnly,
    this.keyboardType,
    this.maxLength,
    this.hint,
    this.border,
    this.prefix,
    this.maxLines,
    this.suffixIcon,
    this.onTap,
    this.textCapitalization,
    this.prefixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
      child: Column(
        children: [
          TextFormField(
            textCapitalization:
                textCapitalization ?? TextCapitalization.sentences,
            cursorColor: primaryColor,
            onTap: onTap as void Function()?,
            autofocus: false,
            controller: controller,
            style: Theme.of(context).textTheme.bodySmall,
            readOnly: readOnly ?? false,
            keyboardType: keyboardType,
            minLines: 1,
            maxLength: maxLength,
            maxLines: maxLines,
            validator: validator,
            decoration: InputDecoration(
              alignLabelWithHint: true,
              prefix: prefix,
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon,
              labelText: label,
              hintText: hint,
              hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: Colors.grey,
                fontSize: 15,
              ),
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              counter: Offstage(),
              icon: (image != null)
                  ? ImageIcon(
                      AssetImage(image!),
                      color: primaryColor,
                      size: 20.0,
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

