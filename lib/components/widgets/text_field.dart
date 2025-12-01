import 'package:flutter/material.dart';
import 'package:ryde_rw/theme/colors.dart';

class EntryField extends StatelessWidget {
  final String? labelText;
  final String? hintText;
  final bool showSuffixIcon;
  final int? maxLines;
  final TextEditingController? controller;

  const EntryField(
    this.labelText,
    this.hintText,
    this.showSuffixIcon, {
    super.key,
    this.maxLines,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final TextEditingController effectiveController =
        controller ?? TextEditingController();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          labelText ?? '',
          textAlign: TextAlign.start,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge!.copyWith(color: Colors.black, fontSize: 13.5),
        ),
        SizedBox(height: 5),
        TextFormField(
          controller: effectiveController,
          maxLines: maxLines,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium!.copyWith(color: Colors.grey),
          decoration: InputDecoration(
            isDense: true,
            suffixIcon: showSuffixIcon
                ? Icon(Icons.arrow_drop_down_outlined, color: Colors.grey)
                : null,
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            hintText: hintText,
            hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
              fontSize: 13.5,
              color: Color(0xffb3b3b3),
            ),
          ),
        ),
        SizedBox(height: 30),
      ],
    );
  }
}

class EntryFieldR extends StatelessWidget {
  final String? labelText;
  final String? hintText;
  final bool showSuffixIcon;
  final TextEditingController controller; // Declare controller here

  const EntryFieldR(
    this.labelText,
    this.hintText,
    this.showSuffixIcon, {
    super.key,
    required this.controller,
  }); // Required controller in the constructor

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          labelText ?? '',
          textAlign: TextAlign.start,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge!.copyWith(color: Colors.grey, fontSize: 13.5),
        ),
        SizedBox(height: 5),
        TextFormField(
          controller: controller, // Attach controller to capture input
          style: Theme.of(
            context,
          ).textTheme.bodyMedium!.copyWith(color: Colors.grey, fontSize: 13.5),
          decoration: InputDecoration(
            isDense: true,
            suffixIcon: showSuffixIcon
                ? Icon(Icons.verified_user, color: primaryColor, size: 17)
                : null,
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            hintText: hintText,
            hintStyle: Theme.of(
              context,
            ).textTheme.bodyLarge!.copyWith(fontSize: 13.5),
          ),
        ),
        SizedBox(height: 30),
      ],
    );
  }
}

class TextFieldInput extends StatelessWidget {
  final String? labelText;
  final bool readOnly;
  final String? hintText;
  final bool showSuffixIcon;
  final TextEditingController? controller;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;

  const TextFieldInput({
    super.key,
    this.labelText,
    this.hintText,
    this.showSuffixIcon = false,
    this.controller,
    this.onChanged,
    this.validator,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (labelText != null)
          Text(
            labelText!,
            textAlign: TextAlign.start,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge!.copyWith(color: Colors.grey, fontSize: 13.5),
          ),
        const SizedBox(height: 5),
        TextFormField(
          readOnly: readOnly,
          controller: controller,
          onChanged: onChanged,
          validator: validator,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium!.copyWith(color: Colors.grey, fontSize: 13.5),
          decoration: InputDecoration(
            isDense: true,
            suffixIcon: showSuffixIcon
                ? Icon(
                    Icons.verified_user,
                    color: Theme.of(context).primaryColor,
                    size: 17,
                  )
                : null,
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            errorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red),
            ),
            hintText: hintText,
            hintStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(
              fontSize: 13.5,
              color: Colors.grey[400],
            ),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}
