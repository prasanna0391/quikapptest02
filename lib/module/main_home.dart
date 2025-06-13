import 'dart:async';
import 'dart:convert';

import 'dart:io';


import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '/config/env_config.dart';
import '/services/notification_service.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '/chat/chat_widget.dart';

import '../config/trusted_domains.dart';
// import '../utils/icon_parser.dart';




class MainHome extends StatefulWidget {
  final String webUrl;
  final bool isBottomMenu;
  final String bottomMenuItems;
  final bool isDeeplink;
  final String backgroundColor;
  final String activeTabColor;
  final String textColor;
  final String iconColor;
  final String iconPosition;
  final String taglineColor;
  final bool isLoadIndicator;
  const MainHome({super.key, required this.webUrl, required this.isBottomMenu, required this.bottomMenuItems, required this.isDeeplink, required this.backgroundColor, required this.activeTabColor, required this.textColor, required this.iconColor, required this.iconPosition, required this.taglineColor, required this.isLoadIndicator});

  @override
  State<MainHome> createState() => _MainHomeState();
}

class _MainHomeState extends State<MainHome> {
  final GlobalKey webViewKey = GlobalKey();
  final String BMFont =  String.fromEnvironment('BOTTOMMENU_FONT', defaultValue: 'Public Sans');
  final double BMFontSize = double.tryParse( String.fromEnvironment('BOTTOMMENU_FONT_SIZE', defaultValue: "14")) ?? 12;
  final bool BMisBold =  bool.fromEnvironment('BOTTOMMENU_FONT_BOLD', defaultValue: false);
  final bool BMisItalic =  bool.fromEnvironment('BOTTOMMENU_FONT_ITALIC', defaultValue: true);
  final bool isChatBot =  bool.fromEnvironment('IS_CHATBOT', defaultValue: true);
  late bool isBottomMenu;

  // final Color taglineColor = _parseHexColor(const String.fromEnvironment('SPLASH_TAGLINE_COLOR', defaultValue: "#000000"));
  int _currentIndex = 0;

  InAppWebViewController? webViewController;
  WebViewEnvironment? webViewEnvironment;
  late PullToRefreshController? pullToRefreshController;



  static Color _parseHexColor(String hexColor) {
    hexColor = hexColor.replaceFirst('#', '');
    if (hexColor.length == 6) hexColor = 'FF$hexColor';
    return Color(int.parse('0x$hexColor'));
  }

  bool? hasInternet;
// Convert the JSON string into a List of menu objects
  List<Map<String, dynamic>> bottomMenuItems = [];

  String url = "";
  double progress = 0;
  final urlController = TextEditingController();
  DateTime? _lastBackPressed;
  String? _pendingInitialUrl; // 🔹 NEW
  bool isChatVisible = false;

  String myDomain = "";

  InAppWebViewSettings settings = InAppWebViewSettings(
    isInspectable: kDebugMode,
    mediaPlaybackRequiresUserGesture: false,
    allowsInlineMediaPlayback: true,
    iframeAllow: "camera; microphone",
    iframeAllowFullscreen: true,
  );

  Offset _dragPosition = const Offset(16, 300); // Initial position for chat toggle
  String get InitialCurrentURL => widget.webUrl;

  void requestPermissions() async {
    if (isCameraEnabled) await Permission.camera.request();
    if (isLocationEnabled) await Permission.location.request(); // GPS
    if (isMicEnabled) await Permission.microphone.request();
    if (isContactEnabled) await Permission.contacts.request();
    if (isCalendarEnabled) await Permission.calendar.request();
    if (isNotificationEnabled) await Permission.notification.request();

    // Always request storage (as per your logic)
    await Permission.storage.request();
    if (isBiometricEnabled) {
      if (Platform.isIOS) {
        // Use raw value 33 for faceId (iOS)
        await Permission.byValue(33).request();
      } else if (Platform.isAndroid) {
        // No need to request biometric permission manually on Android
        // It's requested automatically by biometric plugins like local_auth
      }
    }
  }

  @override
  void initState() {
    super.initState();

    if (pushNotify) {
      try {
        // Only access FirebaseMessaging after ensuring Firebase is initialized
        Future.delayed(Duration.zero, () async {
          final token = await FirebaseMessaging.instance.getToken();
          if (kDebugMode) {
            print("🔑 Firebase Token: $token");
          }
        });
      } catch (e) {
        if (kDebugMode) {
          print("🚨 Error accessing FirebaseMessaging.instance: $e");
        }
      }
    } else {
      if (kDebugMode) {
        print("📭 pushNotify is false. Skipping FirebaseMessaging setup.");
      }
    }

    requestPermissions();

    if (pushNotify == true) {
      setupFirebaseMessaging();
      // Handle terminated state
      FirebaseMessaging.instance.getInitialMessage().then((message) async {
        if (message != null) {
          final internalUrl = message.data['url'];
          if (internalUrl != null && internalUrl.isNotEmpty) {
            _pendingInitialUrl = internalUrl;
          }
          await _showLocalNotification(message);
        }
      });
    }

    isBottomMenu = widget.isBottomMenu;

    if (isBottomMenu == true) {
      try {
        bottomMenuItems = parseBottomMenuItems(widget.bottomMenuItems);
        // bottomMenuItems = widget.bottomMenuItems;
      } catch (e) {
        if (kDebugMode) {
          print("Invalid bottom menu JSON: $e");
        }
      }
    }

    Connectivity().onConnectivityChanged.listen((_) {
      _checkInternetConnection();
    });

    _checkInternetConnection();

    if (!kIsWeb &&
        [TargetPlatform.android, TargetPlatform.iOS].contains(defaultTargetPlatform) &&
        isPullDown) {
      pullToRefreshController = PullToRefreshController(
          settings: PullToRefreshSettings(color:  _parseHexColor(widget.taglineColor)),
          onRefresh: () async {
            try {
              if (defaultTargetPlatform == TargetPlatform.android) {
                await webViewController?.reload();
              } else if (defaultTargetPlatform == TargetPlatform.iOS) {
                final currentUrl = await webViewController?.getUrl();
                if (currentUrl != null) {
                  await webViewController?.loadUrl(
                    urlRequest: URLRequest(url: currentUrl),
                  );
                }
              }
            } catch (e) {
              debugPrint('❌ Refresh error: $e');
            } finally {
              pullToRefreshController?.endRefreshing(); // ✅ Important!
            }
          }
      );
    } else {
      pullToRefreshController = null;
    }


    Uri parsedUri = Uri.parse(widget.webUrl);
    myDomain = parsedUri.host;
    if (myDomain.startsWith('www.')) {
      myDomain = myDomain.substring(4);
    }
  }



  /// ✅ Navigation from notification
  void _handleNotificationNavigation(RemoteMessage message) {
    final internalUrl = message.data['url'] ;
    if (internalUrl != null && webViewController != null) {
      webViewController?.loadUrl(
        urlRequest: URLRequest(url: WebUri(internalUrl ?? widget.webUrl)),
      );
    }
  }

  /// ✅ Setup push notification logic
  void setupFirebaseMessaging() async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        await messaging.subscribeToTopic('all_users');
        // Platform-specific topics
        if (Platform.isAndroid) {
          await messaging.subscribeToTopic('android_users');
        } else if (Platform.isIOS) {
          await messaging.subscribeToTopic('ios_users');
        }
      } else {
        if (kDebugMode) {
          print("Notification permission not granted.");
        }
      }

      // ✅ Listen for foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        await _showLocalNotification(message);
        _handleNotificationNavigation(message);
      });

      // ✅ Handle background tap
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint("📲 Opened from background tap: ${message.data}");
        _handleNotificationNavigation(message);
      });

    } catch (e) {
      if (kDebugMode) {
        print("❌ Error during Firebase Messaging setup: $e");
      }
    }
  }


  /// ✅ Local push with optional image
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = notification?.android;
    final imageUrl = notification?.android?.imageUrl ?? message.data['image'];

    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Default',
      channelDescription: 'Default notification channel',
      importance: Importance.max,
      priority: Priority.high,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction('id_1', 'View'),
        AndroidNotificationAction('id_2', 'Dismiss'),
      ],
    );

    if (notification != null && android != null) {
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          final http.Response response = await http.get(Uri.parse(imageUrl));
          final tempDir = await getTemporaryDirectory();
          final filePath = '${tempDir.path}/notif_image.jpg';
          final file = File(filePath);
          await file.writeAsBytes(response.bodyBytes);

          androidDetails = AndroidNotificationDetails(
            'default_channel',
            'Default',
            channelDescription: 'Default notification channel',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            icon: '@mipmap/ic_launcher',
            styleInformation: BigPictureStyleInformation(
              FilePathAndroidBitmap(filePath),
              largeIcon: FilePathAndroidBitmap(filePath),
              contentTitle: '<b>${notification.title}</b>',
              summaryText: notification.body,
              htmlFormatContentTitle: true,
              htmlFormatSummaryText: true,
            ),
          );
        } catch (e) {
          if (kDebugMode) {
            print('❌ Failed to load image: $e');
          }
          androidDetails = androidDetails;
        }
      } else {
        androidDetails = androidDetails;
      }

      final DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        attachments: imageUrl != null ? [DarwinNotificationAttachment(imageUrl)] : null,
      );

      NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        platformDetails,
      );
    }
  }

  /// ✅ Connectivity
  Future<void> _checkInternetConnection() async {
    final result = await Connectivity().checkConnectivity();
    final isOnline = result != ConnectivityResult.none;
    if (mounted) {
      setState(() {
        hasInternet = isOnline;
      });
    }
  }

  /// ✅ Back button double-press exit
  Future<bool> _onBackPressed() async {
    if (webViewController != null) {
      bool canGoBack = await webViewController!.canGoBack();
      if (canGoBack) {
        await webViewController!.goBack();
        return false; // Don't exit app
      }
    }

    DateTime now = DateTime.now();
    if (_lastBackPressed == null || now.difference(_lastBackPressed!) > Duration(seconds: 2)) {
      _lastBackPressed = now;
      Fluttertoast.showToast(
        msg: "Press back again to exit",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
      );
      return false;
    }

    return true; // Exit app
  }

  bool isLoading = true;
  bool hasError = false;
  TextStyle _getMenuTextStyle(bool isActive) {
    return GoogleFonts.getFont(
      BMFont,
      fontSize: BMFontSize,
      fontWeight: BMisBold ? FontWeight.bold : FontWeight.normal,
      fontStyle: BMisItalic ? FontStyle.italic : FontStyle.normal,
      color: isActive
          ? _parseHexColor(widget.activeTabColor)
          : _parseHexColor(widget.textColor),
    );
  }
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Builder(
                builder: (context) {
                  if (hasInternet == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (hasInternet == false) {
                    return const Center(child: Text('📴 No Internet Connection'));
                  }

                  return Stack(
                    children: [
                      if (!hasError)
                        InAppWebView(
                          key: webViewKey,
                          webViewEnvironment: webViewEnvironment,
                          initialUrlRequest: URLRequest(url: WebUri(widget.webUrl.isNotEmpty ? widget.webUrl : "https://pixaware.co"),),
                          pullToRefreshController: pullToRefreshController,
                          onWebViewCreated: (controller) {
                            webViewController = controller;
                            if (_pendingInitialUrl != null) {
                              controller.loadUrl(
                                urlRequest: URLRequest(url: WebUri(_pendingInitialUrl!)),
                              );
                              _pendingInitialUrl = null;
                            }
                          },
                          shouldOverrideUrlLoading: (controller, navigationAction) async {
                            final uri = navigationAction.request.url;
                            if (uri != null) {
                              final urlStr = uri.toString();

                              // Block Google reCAPTCHA
                              if (urlStr.contains("google.com/recaptcha")) {
                                debugPrint("Blocked reCAPTCHA URL: $urlStr");
                                return NavigationActionPolicy.CANCEL;
                              }

                              // If it's your domain OR trusted payment domain → open in app
                              if (uri.host.contains(myDomain) || isTrustedPaymentDomain(urlStr)) {
                                return NavigationActionPolicy.ALLOW;
                              }

                              // Otherwise open in external browser if deeplink is allowed
                              if (widget.isDeeplink) {
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                  return NavigationActionPolicy.CANCEL;
                                }
                              }

                              // External links blocked
                              Fluttertoast.showToast(
                                msg: "External links are disabled",
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.BOTTOM,
                              );
                              return NavigationActionPolicy.CANCEL;
                            }
                            return NavigationActionPolicy.ALLOW;
                          },
                          onLoadStart: (controller, url) {
                            setState(() {
                              isLoading = true;
                              hasError = false;
                            });
                          },
                          onLoadStop: (controller, url) async {
                            setState(() => isLoading = false);
                          },
                          onLoadError: (controller, url, code, message) {
                            debugPrint('Load error [$code]: $message');
                            setState(() {
                              hasError = true;
                              isLoading = false;
                            });
                          },
                          onLoadHttpError: (controller, url, statusCode, description) {
                            debugPrint('HTTP error [$statusCode]: $description');
                            setState(() {
                              hasError = true;
                              isLoading = false;
                            });
                          },
                          onConsoleMessage: (controller, consoleMessage) {
                            debugPrint('Console: ${consoleMessage.message}');
                          },
                        ),

                      // Loading Indicator
                      if (widget.isLoadIndicator && isLoading)
                        const Center(child: CircularProgressIndicator()),

                      // Error Screen
                      if (hasError)
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 64, color: Colors.red),
                              const SizedBox(height: 16),
                              const Text(
                                "Oops! Couldn't load the App.",
                                style: TextStyle(fontSize: 18),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    hasError = false;
                                    isLoading = true;
                                  });
                                  webViewController?.loadUrl(
                                    urlRequest: URLRequest(url: WebUri(widget.webUrl)),
                                  );
                                },
                                child: const Text("Retry"),
                              ),
                            ],
                          ),
                        ),

                      // Chat Widget
                      if (isChatVisible && webViewController != null && isChatBot)
                        Positioned(
                          right: MediaQuery.of(context).size.width * 0.05,
                          bottom: MediaQuery.of(context).size.height * 0.05,
                          top: MediaQuery.of(context).size.height * 0.05,
                          left: MediaQuery.of(context).size.width * 0.05,
                          child: ChatWidget(
                            webViewController: webViewController!,
                            currentUrl: InitialCurrentURL,
                            onVisibilityChanged: (visible) => setState(() => isChatVisible = visible),
                          ),
                        ),

                      // Chat Toggle Button
                      if (isChatBot)
                        Positioned(
                          left: _dragPosition.dx,
                          top: _dragPosition.dy,
                          child: Draggable(
                            feedback: chatToggleButton(isChatVisible, null),
                            childWhenDragging: const SizedBox.shrink(),
                            onDragEnd: (details) {
                              setState(() {
                                _dragPosition = Offset(
                                  details.offset.dx.clamp(
                                    0.0,
                                    MediaQuery.of(context).size.width - 60,
                                  ),
                                  details.offset.dy.clamp(
                                    0.0,
                                    MediaQuery.of(context).size.height - 60,
                                  ),
                                );
                              });
                            },
                            child: chatToggleButton(
                              isChatVisible,
                              () => setState(() => isChatVisible = !isChatVisible),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        bottomNavigationBar: isBottomMenu
            ? BottomAppBar(
          height: 70,
          padding: EdgeInsets.all(0),
          clipBehavior: Clip.none,
          notchMargin: 3.0,
                color: _parseHexColor(widget.backgroundColor),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(
                    bottomMenuItems.length,
                    (index) {
                      final item = bottomMenuItems[index];
                      final isActive = _currentIndex == index;
                      
                      return FutureBuilder<Widget>(
                        future: buildMenuIcon(
                          item,
                          isActive,
                          _parseHexColor(widget.activeTabColor),
                          _parseHexColor(widget.iconColor),
                        ),
                        builder: (context, snapshot) {
                          Widget icon = snapshot.data ?? const SizedBox(width: 24, height: 24);
                          final label = Text(item['label'], style: _getMenuTextStyle(isActive));
                          
                          Widget menuItem;
                          switch (widget.iconPosition) {
                            case 'above':
                              menuItem = Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [icon, label],
                              );
                            case 'beside':
                              menuItem = Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [icon, const SizedBox(width: 4), label],
                              );
                            case 'only_text':
                              menuItem = label;
                            case 'only_icon':
                              menuItem = icon;
                            default:
                              menuItem = Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [icon, label],
                              );
                          }

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _currentIndex = index;
                                webViewController?.loadUrl(
                                  urlRequest: URLRequest(
                                    url: WebUri(item['url']),
                                  ),
                                );
                              });
                            },
                            child: menuItem,
                          );
                        },
                      );
                    },
                  ),
                ),
              )
            : null,
      ),
    );
  }
  Widget chatToggleButton(bool isVisible, VoidCallback? onPressed) {
    return SizedBox(
      height: 60,
      width: 60,
      child: isChatBot == true ?ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          backgroundColor: isVisible ? Colors.red : Colors.indigo,
          padding: const EdgeInsets.all(12),
          elevation: 6,
          shadowColor: Colors.black54,
        ),
        child: Icon(
          isVisible ? Icons.chat : Icons.chat_bubble_outline,
          color: Colors.white,
          size: 25,
        ),
      ):null,
    );
  }

  Future<Widget> buildMenuIcon(Map<String, dynamic> item, bool isActive, Color activeColor, Color defaultColor) async {
    final iconData = item['icon'];
    if (iconData == null) return Icon(Icons.error);

    if (iconData['type'] == 'preset') {
      return Icon(
        _getIconByName(iconData['name'] ?? ''),
        color: isActive ? activeColor : defaultColor,
      );
    }

    if (iconData['type'] == 'custom' && iconData['icon_url'] != null) {
      final labelSanitized = (item['label'] as String).toLowerCase().replaceAll(RegExp(r'\s+'), '_');
      final fileName = '$labelSanitized.svg';

      final dir = await getApplicationSupportDirectory();
      final filePath = '${dir.path}/$fileName';
      final file = File(filePath);

      if (!await file.exists()) {
        try {
          final response = await http.get(Uri.parse(iconData['icon_url']));
          if (response.statusCode == 200) {
            await file.writeAsBytes(response.bodyBytes);
          } else {
            debugPrint('Failed to download SVG for ${item['label']}');
            return Icon(Icons.broken_image);
          }
        } catch (e) {
          debugPrint('Error downloading SVG: $e');
          return Icon(Icons.broken_image);
        }
      }

      return SvgPicture.file(
        file,
        width: double.tryParse(iconData['icon_size'] ?? '24') ?? 24,
        height: double.tryParse(iconData['icon_size'] ?? '24') ?? 24,
        colorFilter: ColorFilter.mode(isActive ? activeColor : defaultColor, BlendMode.srcIn),
        placeholderBuilder: (_) => Icon(Icons.image_not_supported),
      );
    }

    return Icon(Icons.help_outline);
  }
}



List<Map<String, dynamic>> parseBottomMenuItems(String raw) {
  try {
    return List<Map<String, dynamic>>.from(json.decode(raw));
  } catch (e) {
    debugPrint("❌ Failed to parse BOTTOMMENU_ITEMS: $e");
    return [];
  }
}

List<Map<String, dynamic>> convertIcons(List<Map<String, dynamic>> items) {
  return items.map((item) {
    return {
      "label": item["label"],
      "icon": _getIconByName(item["icon"]),
      "url": item["url"],
    };
  }).toList();
}

IconData _getIconByName(String? name) {
  if (name == null || name.trim().isEmpty) {
    return Icons.apps; // Default icon
  }

  final lowerName = name.toLowerCase().trim();

  final iconMap = {
    'ac_unit': Icons.ac_unit,
    'access_alarm': Icons.access_alarm,
    'access_time': Icons.access_time,
    'account_balance': Icons.account_balance,
    'account_circle': Icons.account_circle,
    'add': Icons.add,
    'add_a_photo': Icons.add_a_photo,
    'alarm': Icons.alarm,
    'android': Icons.android,
    'announcement': Icons.announcement,
    'apps': Icons.apps,
    'archive': Icons.archive,
    'arrow_back': Icons.arrow_back,
    'arrow_downward': Icons.arrow_downward,
    'arrow_forward': Icons.arrow_forward,
    'arrow_upward': Icons.arrow_upward,
    'aspect_ratio': Icons.aspect_ratio,
    'assessment': Icons.assessment,
    'assignment': Icons.assignment,
    'autorenew': Icons.autorenew,
    'backup': Icons.backup,
    'battery_alert': Icons.battery_alert,
    'battery_charging_full': Icons.battery_charging_full,
    'beach_access': Icons.beach_access,
    'block': Icons.block,
    'bluetooth': Icons.bluetooth,
    'book': Icons.book,
    'bookmark': Icons.bookmark,
    'bug_report': Icons.bug_report,
    'build': Icons.build,
    'calendar_today': Icons.calendar_today,
    'camera': Icons.camera,
    'card_giftcard': Icons.card_giftcard,
    'chat': Icons.chat,
    'check': Icons.check,
    'chevron_left': Icons.chevron_left,
    'chevron_right': Icons.chevron_right,
    'close': Icons.close,
    'cloud': Icons.cloud,
    'code': Icons.code,
    'comment': Icons.comment,
    'compare': Icons.compare,
    'computer': Icons.computer,
    'content_copy': Icons.content_copy,
    'create': Icons.create,
    'delete': Icons.delete,
    'desktop_mac': Icons.desktop_mac,
    'done': Icons.done,
    'download': Icons.download,
    'drag_handle': Icons.drag_handle,
    'edit': Icons.edit,
    'email': Icons.email,
    'error': Icons.error,
    'event': Icons.event,
    'explore': Icons.explore,
    'face': Icons.face,
    'favorite': Icons.favorite,
    'feedback': Icons.feedback,
    'file_copy': Icons.file_copy,
    'filter_list': Icons.filter_list,
    'flag': Icons.flag,
    'folder': Icons.folder,
    'format_align_left': Icons.format_align_left,
    'format_bold': Icons.format_bold,
    'forward': Icons.forward,
    'fullscreen': Icons.fullscreen,
    'gps_fixed': Icons.gps_fixed,
    'grade': Icons.grade,
    'group': Icons.group,
    'help': Icons.help,
    'highlight': Icons.highlight,
    'home': Icons.home,
    'hourglass_empty': Icons.hourglass_empty,
    'http': Icons.http,
    'https': Icons.https,
    'image': Icons.image,
    'info': Icons.info,
    'input': Icons.input,
    'invert_colors': Icons.invert_colors,
    'keyboard': Icons.keyboard,
    'label': Icons.label,
    'language': Icons.language,
    'launch': Icons.launch,
    'link': Icons.link,
    'list': Icons.list,
    'lock': Icons.lock,
    'map': Icons.map,
    'menu': Icons.menu,
    'message': Icons.message,
    'mic': Icons.mic,
    'mood': Icons.mood,
    'more_horiz': Icons.more_horiz,
    'more_vert': Icons.more_vert,
    'navigation': Icons.navigation,
    'notifications': Icons.notifications,
    'offline_bolt': Icons.offline_bolt,
    'palette': Icons.palette,
    'person': Icons.person,
    'phone': Icons.phone,
    'photo': Icons.photo,
    'place': Icons.place,
    'play_arrow': Icons.play_arrow,
    'print': Icons.print,
    'refresh': Icons.refresh,
    'remove': Icons.remove,
    'reorder': Icons.reorder,
    'reply': Icons.reply,
    'report': Icons.report,
    'save': Icons.save,
    'schedule': Icons.schedule,
    'school': Icons.school,
    'search': Icons.search,
    'security': Icons.security,
    'send': Icons.send,
    'settings': Icons.settings,
    'share': Icons.share,
    'shopping_cart': Icons.shopping_cart,
    'star': Icons.star,
    'store': Icons.store,
    'sync': Icons.sync,
    'thumb_up': Icons.thumb_up,
    'title': Icons.title,
    'translate': Icons.translate,
    'trending_up': Icons.trending_up,
    'update': Icons.update,
    'verified_user': Icons.verified_user,
    'visibility': Icons.visibility,
    'volume_up': Icons.volume_up,
    'warning': Icons.warning,
    'watch': Icons.watch,
    'wifi': Icons.wifi,
    'about': Icons.info,
    'contact': Icons.contact_page,
    'shop': Icons.storefront,
    'cart': Icons.shopping_cart_outlined,
    'shoppingcart': Icons.shopping_cart,
    'orders': Icons.receipt_long,
    'order': Icons.receipt_long,
    'wishlist': Icons.favorite,
    'like': Icons.favorite,
    'category': Icons.category,
    'account': Icons.account_circle,
    'profile': Icons.account_circle,
    'offer': Icons.local_offer,
    'discount': Icons.local_offer,
    'services': Icons.miscellaneous_services,
    'blogs': Icons.article,
    'blog': Icons.article,
    'company': Icons.business,
    'aboutus': Icons.business,
    'more': Icons.more_horiz,
    'home_outline': Icons.home_outlined,
    'search_outline': Icons.search_outlined,
    'person_outline': Icons.person_outline,
    'settings_outline': Icons.settings_outlined,
    'favorite_outline': Icons.favorite_outline,
    'info_outline': Icons.info_outline,
    'help_outline': Icons.help_outline,
    'lock_outline': Icons.lock_outline,
    'visibility_outline': Icons.visibility_outlined,
    'calendar_today_outline': Icons.calendar_today_outlined,
    'check_circle_outline': Icons.check_circle_outline,
    'delete_outline': Icons.delete_outline,
    'edit_outlined': Icons.edit_outlined,
    'language_outlined': Icons.language_outlined,
    'star_outline': Icons.star_outline,
    'map_outlined': Icons.map_outlined,
    'menu_outlined': Icons.menu_outlined,
    'notifications_none': Icons.notifications_none,
    'camera_outlined': Icons.camera_outlined,
    'email_outlined': Icons.email_outlined,
    'shopping_cart_outlined': Icons.shopping_cart_outlined,
    'account_circle_outlined': Icons.account_circle_outlined,
    'calendar_today_outlined': Icons.calendar_today_outlined,
    'home_outlined': Icons.home_outlined,
    'search_outlined': Icons.search_outlined,
    'visibility_outlined': Icons.visibility_outlined,
  };

  final icon = iconMap[lowerName];
  if (icon == null) {
    if (kDebugMode) {
      print("🚫 Icon not found for name: $name");
    }
  }
  return icon ?? Icons.error_outline;
}
