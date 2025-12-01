import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ryde_rw/components/widgets/color_button.dart';

import 'package:ryde_rw/shared/shared_states.dart';
import 'package:ryde_rw/theme/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChangeLanguage extends ConsumerStatefulWidget {
  final bool isStart;

  const ChangeLanguage({super.key, this.isStart = false});

  @override
  ChangeLanguageState createState() => ChangeLanguageState();
}

class ChangeLanguageState extends ConsumerState<ChangeLanguage> {
  int? _selectedLanguage = -1;

  @override
  void initState() {
    super.initState();
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedLocaleCode = prefs.getString('locale');

    setState(() {
      if (savedLocaleCode == 'en') {
        _selectedLanguage = 0;
      } else if (savedLocaleCode == 'fr') {
        _selectedLanguage = 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Locale> supportedLocales = [Locale("en"), Locale("fr")];

    List<String> languages = ["English", "Français"];

    return Scaffold(
      appBar: AppBar(elevation: 0, backgroundColor: backgroundColor),
      body: Column(
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            color: backgroundColor,
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Language",
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge!.copyWith(fontSize: 22),
                    ),
                    SizedBox(width: 20),
                    Text(
                      "Preferred Language",
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium!.copyWith(fontSize: 15),
                    ),
                  ],
                ),
                Spacer(),
                Expanded(
                  flex: 6,
                  child: FadedScaleAnimation(
                    scaleDuration: const Duration(milliseconds: 600),
                    child: Image.asset("assets/head_support.png"),
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
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ListView.builder(
                  padding: EdgeInsets.only(bottom: 50),
                  physics: NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: languages.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Container(
                      margin: EdgeInsets.symmetric(vertical: 2),
                      child: RadioListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        activeColor: primaryColor,
                        title: Text(
                          languages[index],
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge!.copyWith(fontSize: 17),
                        ),
                        value: index,
                        groupValue: _selectedLanguage,
                        onChanged: (val) {
                          setState(() {
                            _selectedLanguage = val;
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                // if (_selectedLanguage != -1) {
                //   ref.read(localeProvider.notifier).state =
                //       supportedLocales[_selectedLanguage!];
                //   String localeCode = _selectedLanguage == 0 ? 'en' : 'fr';
                //   await prefs.setString('locale', localeCode);
                //   Navigator.pop(context);
                // }
              },
              child: FadedScaleAnimation(
                scaleDuration: const Duration(milliseconds: 600),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: SizedBox(height: 55, child: ColorButton("Submit")),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
