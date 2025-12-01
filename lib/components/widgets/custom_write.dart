import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ryde_rw/theme/colors.dart';

class Header extends StatefulWidget {
  final String text;
  const Header({super.key, required this.text});

  @override
  State<Header> createState() => _HeaderState();
}

class _HeaderState extends State<Header> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Text(
        widget.text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: kMainColor,
          fontFamily: GoogleFonts.poppins().fontFamily,
        ),
      ),
    );
  }
}

class H1 extends StatelessWidget {
  final String text;
  const H1({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 18,
          color: kMainColor,
          fontFamily: GoogleFonts.poppins().fontFamily,
        ),
      ),
    );
  }
}

class H2 extends StatelessWidget {
  final String text;
  const H2({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          color: kMainColor,
          fontFamily: GoogleFonts.poppins().fontFamily,
        ),
      ),
    );
  }
}

class P extends StatelessWidget {
  final String text;
  const P({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontFamily: GoogleFonts.poppins().fontFamily,
        ),
      ),
    );
  }
}

class AppDot extends StatefulWidget {
  const AppDot({super.key});

  @override
  State<AppDot> createState() => _AppDotState();
}

class _AppDotState extends State<AppDot> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 5),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black,
      ),
      width: 10,
      height: 10,
    );
  }
}

class Li extends StatelessWidget {
  final String text;
  const Li({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppDot(),
        const SizedBox(width: 10),
        Expanded(child: P(text: text)),
      ],
    );
  }
}

