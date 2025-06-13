import 'package:flutter/material.dart';

import '../config/env_config.dart';
import 'main_home.dart' show MainHome;
import 'splash_screen.dart';

class MyApp extends StatefulWidget {

  final String webUrl;
  final bool isBottomMenu;
  final bool isSplash;
  final String splashLogo;
  final String splashBg;
  final int splashDuration;
  final String splashAnimation;
  final bool isDeeplink;
  final String backgroundColor;
  final String activeTabColor;
  final String textColor;
  final String iconColor;
  final String iconPosition;
  final String taglineColor;
  final String spbgColor;
  final bool isLoadIndicator;
  final String bottomMenuItems;
  const MyApp({super.key, required this.webUrl, required this.isBottomMenu, required this.isSplash, required this.splashLogo, required this.splashBg, required this.splashDuration, required this.splashAnimation, required this.bottomMenuItems, required this.isDeeplink, required this.backgroundColor, required this.activeTabColor, required this.textColor, required this.iconColor, required this.iconPosition, required this.taglineColor, required this.spbgColor, required this.isLoadIndicator});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool showSplash =isSplashEnabled;

  @override
  void initState() {
    super.initState();
    if (showSplash) {
      Future.delayed(Duration(seconds: splashDuration), () {
        setState(() {
          showSplash = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: showSplash
          ? SplashScreen(splashLogo: widget.splashLogo, splashBg: widget.splashBg, splashAnimation: widget.splashAnimation, spbgColor: widget.spbgColor, taglineColor: widget.taglineColor,)
          : MainHome(webUrl: widget.webUrl, isBottomMenu: widget.isBottomMenu, bottomMenuItems: widget.bottomMenuItems, isDeeplink: widget.isDeeplink, backgroundColor: widget.backgroundColor, activeTabColor: widget.activeTabColor, textColor: widget.textColor, iconColor: widget.iconColor, iconPosition: widget.iconPosition, taglineColor: widget.taglineColor, isLoadIndicator: widget.isLoadIndicator,),
    );
  }
}