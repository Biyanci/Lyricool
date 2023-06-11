import 'dart:io';

import 'package:caption_tool/page/full_screen_text_field.dart';
import 'package:caption_tool/page/search_page.dart';
import 'package:caption_tool/page/set_caption_time_view.dart';
import 'package:flutter/material.dart';
import 'color_schemes.g.dart';
import 'model/caption.dart';
import 'page/caption_editing_page.dart';
import 'page/welcome_page.dart';

import 'package:flutter_displaymode/flutter_displaymode.dart';

Future<void> main() async {
  if (Platform.isAndroid) {
    WidgetsFlutterBinding.ensureInitialized();
    await FlutterDisplayMode.setHighRefreshRate();
  }

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: lightColorScheme, useMaterial3: true),
      initialRoute: "/",
      routes: {
        "/": (context) => const WelcomePage(),
        "FullScreenTextField": (context) => const FullScreenTextField(),
        "CaptionEditingPage": (context) => CaptionEditingPage(
              caption: ModalRoute.of(context)!.settings.arguments as LrcCaption,
            ),
        "SetCaptionTimeView": (context) => const SetCaptionTimeView(),
        "SearchPage": (context) => const SearchPage(),
      },
    );
  }
}
