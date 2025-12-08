import 'package:flutter/material.dart';
import 'package:ryde_rw/components/widgets/location_search_modal.dart';
import 'package:ryde_rw/shared/locations_shared.dart';

class DropoffLocationInputField extends StatefulWidget {
  final Widget prefixIcon;
  final String hint;
  final bool destination;
  final Location? location;
  final bool useCurrent;
  final Function(Location) onSelected;
  const DropoffLocationInputField({
    super.key,
    required this.prefixIcon,
    required this.hint,
    required this.destination,
    required this.onSelected,
    required this.location,
    this.useCurrent = false,
  });

  @override
  State<DropoffLocationInputField> createState() => _DropoffLocationInputFieldState();
}

class _DropoffLocationInputFieldState extends State<DropoffLocationInputField> {
  final controller = TextEditingController();

  @override
  initState() {
    super.initState();
    controller.text = widget.location?.address ?? '';
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> openLocationModal(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.8,
          ),
          child: LocationSearchModal(
            destination: widget.destination,
            location: widget.location,
            useCurrent: widget.useCurrent,
            onLocationSelected: (Location newLocation) {
              controller.text = newLocation.address;
              widget.onSelected(newLocation);
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => openLocationModal(context),
      child: AbsorbPointer(
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[100],
            isDense: false,
            contentPadding: const EdgeInsets.only(top: 15),
            prefixIcon: widget.prefixIcon,
            hintText: widget.hint,
            hintStyle: Theme.of(context).textTheme.titleMedium!.copyWith(color: Colors.grey),
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
          ),
        ),
      ),
    );
  }
}

