import 'package:flutter/material.dart';
import 'package:ryde_rw/theme/colors.dart';

ThemeData uiTheme() {
  return ThemeData(
    unselectedWidgetColor: Colors.grey[200],
    fontFamily: 'Poppins',
    // androidOverscrollIndicator: AndroidOverscrollIndicator.stretch,
    tabBarTheme: TabBarThemeData(
      indicatorSize: TabBarIndicatorSize.tab,
      unselectedLabelColor: Colors.grey,
    ),
    appBarTheme: AppBarTheme(iconTheme: IconThemeData(color: Colors.black)),
    scaffoldBackgroundColor: Colors.white,
    dividerColor: backgroundColor,
    primaryColor: Color(0xff0FC874),
    textTheme: TextTheme(
      labelLarge: TextStyle(color: Colors.white),
      bodyLarge: TextStyle(
        color: Color(0xff4d4d4d),
        fontSize: 17,
        fontWeight: FontWeight.w500,
      ),
      bodyMedium: TextStyle(
        color: Color.fromARGB(255, 96, 111, 123),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      headlineSmall: TextStyle(color: Colors.white, fontSize: 20),
      titleMedium: TextStyle(color: Colors.white),
    ),
    colorScheme: ColorScheme.fromSwatch().copyWith(
      secondary: Colors.white,
      background: Color(0xffEBF3F9),
    ),
  );
}

