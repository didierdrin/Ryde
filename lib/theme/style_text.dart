import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ryde_rw/theme/colors.dart';

class AppStyles {
  static TextStyle get homeHeader => GoogleFonts.mulish(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    height: 25.1 / 20,
    color: kBlackColor,
    textBaseline: TextBaseline.alphabetic,
  );

  static TextStyle get searchText => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 21 / 14,
    color: Color(0xFF888888),
    textBaseline: TextBaseline.alphabetic,
  );

  static TextStyle get titleBanner => GoogleFonts.mulish(
    fontSize: 24,
    fontWeight: FontWeight.w900,
    height: 30.12 / 24,
    color: Colors.white,
    textBaseline: TextBaseline.alphabetic,
  );
  static TextStyle get descriptionBanner => GoogleFonts.mulish(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 36.78 / 24,
    color: Colors.white,
  );
  static TextStyle get description => GoogleFonts.mulish(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 36.78 / 24,
    color: const Color(0xff555555),
  );

  static TextStyle get smallBoldTextStyle => GoogleFonts.mulish(
    fontSize: 12,
    fontWeight: FontWeight.w800,
    height: 1.255,
    color: const Color(0xff222222),
  );
  static TextStyle get smallTextStyle => GoogleFonts.mulish(
    fontSize: 12,
    height: 1.255,
    fontWeight: FontWeight.w400,
    color: const Color(0xff101010),
  );

  static TextStyle get recommendationTextStyle => GoogleFonts.poppins(
    fontSize: 12,
    height: 1.255,
    fontWeight: FontWeight.w400,
    color: const Color(0xff101010),
  );

  static TextStyle get productTextStyle => GoogleFonts.mulish(
    fontSize: 14,
    height: 30.78 / 24,
    fontWeight: FontWeight.w700,
    color: const Color(0xff222222),
  );

  static TextStyle get orderTextStyle => GoogleFonts.mulish(
    fontSize: 11,
    height: 20.78 / 24,
    fontWeight: FontWeight.w400,
    color: const Color(0xff555555),
  );

  static TextStyle get buttomTextStyle => GoogleFonts.mulish(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 20.08 / 16,
    color: const Color(0xff222222),
    textBaseline: TextBaseline.alphabetic,
  );

  static TextStyle get headerTextStyle => GoogleFonts.mulish(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    height: 20.08 / 16,
    color: const Color(0xff101010),
    textBaseline: TextBaseline.alphabetic,
  );

  static TextStyle get subHeaderTextStyle => GoogleFonts.mulish(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 20.08 / 16,
    color: const Color(0xff555555),
    textBaseline: TextBaseline.alphabetic,
  );

  static TextStyle get paymentinfoTextStyle => GoogleFonts.mulish(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    height: 20.08 / 16,
    color: const Color(0xff222222),
    textBaseline: TextBaseline.alphabetic,
  );

  static TextStyle get accountTextStyle => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 20.08 / 16,
    color: const Color(0xff555555),
    textBaseline: TextBaseline.alphabetic,
  );

  static TextStyle get customTextStyle => GoogleFonts.mulish(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    height: 20.08 / 16,
    color: Color(0xff222222),
    textBaseline: TextBaseline.alphabetic,
  );
  static TextStyle get viewllTextStyle => GoogleFonts.mulish(
    fontSize: 14,
    fontWeight: FontWeight.w800,
    height: 20.08 / 16,
    color: greenPrimary,
    textBaseline: TextBaseline.alphabetic,
  );

  static TextStyle get categorytextStyle => GoogleFonts.mulish(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 20.08 / 14,
    color: Color(0xff222222),
    textBaseline: TextBaseline.alphabetic,
  );
}

