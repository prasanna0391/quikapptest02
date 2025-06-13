import 'dart:convert';

// Version info
const String versionName = String.fromEnvironment('VERSION_NAME', defaultValue: '1.0.18');
const String versionCode = String.fromEnvironment('VERSION_CODE', defaultValue: '25');

// Keystore config
const String keyStoreUrl = String.fromEnvironment('KEY_STORE', defaultValue: 'https://raw.githubusercontent.com/prasanna91/QuikApp/main/keystore.jks');
const String cmKeystorePassword = String.fromEnvironment('CM_KEYSTORE_PASSWORD', defaultValue: 'opeN@1234');
const String cmKeyAlias = String.fromEnvironment('CM_KEY_ALIAS', defaultValue: 'my_key_alias');
const String cmKeyPassword = String.fromEnvironment('CM_KEY_PASSWORD', defaultValue: 'opeN@1234');

// App info
const String appName = String.fromEnvironment('APP_NAME', defaultValue: 'Pixaware App');
const String orgName = String.fromEnvironment('ORG_NAME', defaultValue: 'Pixaware Technologys');
const String packageName = String.fromEnvironment('PKG_NAME', defaultValue: 'co.pixaware.Pixaware');

// Firebase config
const String firebaseConfigAndroid = String.fromEnvironment('firebase_config_android', defaultValue: 'https://raw.githubusercontent.com/prasanna91/QuikApp/main/google-services-pw.json');
const String firebaseConfigIos = String.fromEnvironment('firebase_config_ios', defaultValue: 'https://raw.githubusercontent.com/prasanna91/QuikApp/main/GoogleService-Info-pw.plist');
const String apnsKeyId = String.fromEnvironment('APNS_KEY_ID', defaultValue: '2W22S6AY3Q');
const String apnsTeamId = String.fromEnvironment('APPLE_TEAM_ID', defaultValue: '9H2AD7NQ49');
const String apnsAuthKeyUrl = String.fromEnvironment('APNS_AUTH_KEY_URL', defaultValue: 'https://raw.githubusercontent.com/prasanna91/QuikApp/main/AuthKey_2W22S6AY3Q.p8');

// General
const String webUrl = String.fromEnvironment('WEB_URL', defaultValue: 'https://pixaware.co/');
const String emailId = String.fromEnvironment('EMAIL_ID', defaultValue: 'prasannasrie@gmail.com');

// Splash screen
const bool isSplashEnabled = bool.fromEnvironment('IS_SPLASH', defaultValue: true);
const String splashBgUrl = String.fromEnvironment('SPLASH_BG', defaultValue: '');
const String splashUrl = String.fromEnvironment('SPLASH', defaultValue: 'https://raw.githubusercontent.com/prasanna91/QuikApp/main/pw-logo.png');
const String splashTagline = String.fromEnvironment('SPLASH_TAGLINE', defaultValue: 'Welcome to Pixaware');
const String splashTaglineColor = String.fromEnvironment('SPLASH_TAGLINE_COLOR', defaultValue: '#E91E63');
const String splashAnimation = String.fromEnvironment('SPLASH_ANIMATION', defaultValue: 'fade');
const int splashDuration = int.fromEnvironment('SPLASH_DURATION', defaultValue: 3);
const String splashBgColor = String.fromEnvironment('SPLASH_BG_COLOR', defaultValue: '#cfc3ba');

// Pull down
const bool isPullDown = bool.fromEnvironment('IS_PULLDOWN', defaultValue: true);

// Logo
const String logoUrl = String.fromEnvironment('LOGO_URL', defaultValue: 'https://raw.githubusercontent.com/prasanna91/QuikApp/main/pw-logo.png');

// Deep linking
const bool isDeepLink = bool.fromEnvironment('IS_DEEPLINK', defaultValue: true);

// Loading indicator
const bool isLoadIndicator = bool.fromEnvironment('IS_LOAD_IND', defaultValue: true);

// Permissions
const bool isCameraEnabled = bool.fromEnvironment('IS_CAMERA', defaultValue: false);
const bool isLocationEnabled = bool.fromEnvironment('IS_LOCATION', defaultValue: false);
const bool isMicEnabled = bool.fromEnvironment('IS_MIC', defaultValue: true);
const bool isNotificationEnabled = bool.fromEnvironment('IS_NOTIFICATION', defaultValue: true);
const bool isContactEnabled = bool.fromEnvironment('IS_CONTACT', defaultValue: false);
const bool isBiometricEnabled = bool.fromEnvironment('IS_BIOMETRIC', defaultValue: false);
const bool isCalendarEnabled = bool.fromEnvironment('IS_CALENDAR', defaultValue: false);
const bool isStorageEnabled = bool.fromEnvironment('IS_STORAGE', defaultValue: true);

// Push notification
const bool pushNotify = bool.fromEnvironment('PUSH_NOTIFY', defaultValue: false);

// Bottom menu
const bool isBottomMenu = bool.fromEnvironment('IS_BOTTOMMENU', defaultValue: true);
const String bottomMenuRaw = String.fromEnvironment(
  'BOTTOMMENU_ITEMS',
  defaultValue: '[{"label":"Home","icon":{"type":"preset","name":"home_outlined"},"url":"https://pixaware.co/"},{"label":"services","icon":{"type":"custom","icon_url":"https://raw.githubusercontent.com/prasanna91/QuikApp/main/card.svg","icon_size":"24"},"url":"https://pixaware.co/solutions/"},{"label":"About","icon":{"type":"custom","icon_url":"https://raw.githubusercontent.com/prasanna91/QuikApp/main/about.svg","icon_size":"24"},"url":"https://pixaware.co/who-we-are/"},{"label":"Contact","icon":{"type":"custom","icon_url":"https://raw.githubusercontent.com/prasanna91/QuikApp/main/contact.svg","icon_size":"24"},"url":"https://pixaware.co/lets-talk/"}]',
);

// '[{"label": "Home", "icon": "shop", "url": "https://pixaware.co/"}, {"label": "services", "icon": "services", "url": "https://pixaware.co/solutions/"}, {"label": "About", "icon": "info", "url": "https://pixaware.co/who-we-are/"}, {"label": "Contact", "icon": "company", "url": "https://pixaware.co/lets-talk/"}]');
final List<Map<String, dynamic>> bottomMenuItems =
(jsonDecode(bottomMenuRaw) as List).map((e) => Map<String, dynamic>.from(e)).toList();

const String bottomMenuBgColor = String.fromEnvironment('BOTTOMMENU_BG_COLOR', defaultValue: '#f0f0e0');
const String bottomMenuIconColor = String.fromEnvironment('BOTTOMMENU_ICON_COLOR', defaultValue: '#888888');
const String bottomMenuTextColor = String.fromEnvironment('BOTTOMMENU_TEXT_COLOR', defaultValue: '#000000');
const String bottomMenuActiveTabColor = String.fromEnvironment('BOTTOMMENU_ACTIVE_TAB_COLOR', defaultValue: '#FF2D55');
const String bottomMenuIconPosition = String.fromEnvironment('BOTTOMMENU_ICON_POSITION', defaultValue: 'above');
const String bottomMenuVisibleOn = String.fromEnvironment('BOTTOMMENU_VISIBLE_ON', defaultValue: 'home,settings,profile');

// Bottom menu font styling (new)
const String bottomMenuFont = String.fromEnvironment('BOTTOMMENU_FONT', defaultValue: 'Montserrat');
const String bottomMenuFontSize = String.fromEnvironment('BOTTOMMENU_FONT_SIZE', defaultValue: '12');
const String bottomMenuFontBold = String.fromEnvironment('BOTTOMMENU_FONT_BOLD', defaultValue: 'false');
const String bottomMenuFontItalic = String.fromEnvironment('BOTTOMMENU_FONT_ITALIC', defaultValue: 'true');

// iOS Certificate
const String certUrl = String.fromEnvironment('CERT_URL', defaultValue: 'https://raw.githubusercontent.com/prasanna91/QuikApp/main/Pixaware_Certificates.p12');
const String certPassword = String.fromEnvironment('CERT_PASSWORD', defaultValue: 'opeN@1234');
const String profileUrl = String.fromEnvironment('PROFILE_URL', defaultValue: 'https://raw.githubusercontent.com/prasanna91/QuikApp/main/Garbcode.mobileprovision');

// import 'dart:convert';
//
// // Versioning
// const String versionName = String.fromEnvironment('VERSION_NAME', defaultValue: '1.0.0');
// const String versionCode = String.fromEnvironment('VERSION_CODE', defaultValue: '1');
//
// // Keystore config
// const String keyStoreUrl = String.fromEnvironment('KEY_STORE');
// const String cmKeystorePassword = String.fromEnvironment('CM_KEYSTORE_PASSWORD');
// const String cmKeyAlias = String.fromEnvironment('CM_KEY_ALIAS');
// const String cmKeyPassword = String.fromEnvironment('CM_KEY_PASSWORD');
//
// // App info
// const String appName = String.fromEnvironment('APP_NAME');
// const String orgName = String.fromEnvironment('ORG_NAME');
// const String packageName = String.fromEnvironment('PKG_NAME');
//
// // Firebase config
// const String firebaseConfigAndroid = String.fromEnvironment('firebase_config_android');
// const String firebaseConfigIos = String.fromEnvironment('firebase_config_ios');
// const String apnsKeyId = String.fromEnvironment('APNS_KEY_ID');
// const String apnsTeamId = String.fromEnvironment('APNS_TEAM_ID');
// const String apnsAuthKeyUrl = String.fromEnvironment('APNS_AUTH_KEY_URL');
//
// // General
// const String webUrl = String.fromEnvironment('WEB_URL');
// const String emailId = String.fromEnvironment('EMAIL_ID');
//
// // Splash screen
// const bool isSplashEnabled = bool.fromEnvironment('IS_SPLASH', defaultValue: false);
// const String splashBgUrl = String.fromEnvironment('SPLASH_BG');
// const String splashUrl = String.fromEnvironment('SPLASH');
// const String splashTagline = String.fromEnvironment('SPLASH_TAGLINE');
// const String splashTaglineColor = String.fromEnvironment('SPLASH_TAGLINE_COLOR');
// const String splashAnimation = String.fromEnvironment('SPLASH_ANIMATION');
// const int splashDuration = int.fromEnvironment('SPLASH_DURATION');
// const String splashBgColor = String.fromEnvironment('SPLASH_BG_COLOR');
//
// // Pull down
// const bool isPullDown = bool.fromEnvironment('IS_PULLDOWN', defaultValue: false);
//
// // Logo
// const String logoUrl = String.fromEnvironment('LOGO_URL');
//
// // Deep linking
// const bool isDeepLink = bool.fromEnvironment('IS_DEEPLINK', defaultValue: false);
//
// const bool isLoadIndicator = bool.fromEnvironment('IS_LOAD_IND', defaultValue: true);
//
// // Permissions
// const bool isCameraEnabled = bool.fromEnvironment('IS_CAMERA', defaultValue: false);
// const bool isLocationEnabled = bool.fromEnvironment('IS_LOCATION', defaultValue: false);
// const bool isMicEnabled = bool.fromEnvironment('IS_MIC', defaultValue: false);
// const bool isNotificationEnabled = bool.fromEnvironment('IS_NOTIFICATION', defaultValue: false);
// const bool isContactEnabled = bool.fromEnvironment('IS_CONTACT', defaultValue: false);
// const bool isBiometricEnabled = bool.fromEnvironment('IS_BIOMETRIC', defaultValue: false);
// const bool isCalendarEnabled = bool.fromEnvironment('IS_CALENDAR', defaultValue: false);
//
// // Push notification
// const bool pushNotify = bool.fromEnvironment('PUSH_NOTIFY', defaultValue: false);
//
// // Bottom menu
// const bool isBottomMenu = bool.fromEnvironment('IS_BOTTOMMENU', defaultValue: false);
// const String bottomMenuRaw = String.fromEnvironment('BOTTOMMENU_ITEMS');
// final List<Map<String, dynamic>> bottomMenuItems =
// (jsonDecode(bottomMenuRaw) as List)
//     .map((e) => Map<String, dynamic>.from(e))
//     .toList();
//
// const String bottomMenuBgColor = String.fromEnvironment('BOTTOMMENU_BG_COLOR');
// const String bottomMenuIconColor = String.fromEnvironment('BOTTOMMENU_ICON_COLOR');
// const String bottomMenuTextColor = String.fromEnvironment('BOTTOMMENU_TEXT_COLOR');
// const String bottomMenuActiveTabColor = String.fromEnvironment('BOTTOMMENU_ACTIVE_TAB_COLOR');
// const String bottomMenuIconPosition = String.fromEnvironment('BOTTOMMENU_ICON_POSITION', defaultValue: 'above');
// const String bottomMenuVisibleOn = String.fromEnvironment('BOTTOMMENU_VISIBLE_ON');
//

// import 'dart:convert';
//
// // Versioning
// const String versionName = String.fromEnvironment('VERSION_NAME', defaultValue: '1.0.0');
// const String versionCode = String.fromEnvironment('VERSION_CODE', defaultValue: '1');
//
// // Keystore config
// const String keyStoreUrl = String.fromEnvironment('KEY_STORE');
// const String cmKeystorePassword = String.fromEnvironment('CM_KEYSTORE_PASSWORD');
// const String cmKeyAlias = String.fromEnvironment('CM_KEY_ALIAS');
// const String cmKeyPassword = String.fromEnvironment('CM_KEY_PASSWORD');
//
// // App info
// const String appName = String.fromEnvironment('APP_NAME');
// const String orgName = String.fromEnvironment('ORG_NAME');
// const String packageName = String.fromEnvironment('PKG_NAME');
//
// // Firebase config
// const String firebaseConfigAndroid = String.fromEnvironment('firebase_config_android');
// const String firebaseConfigIos = String.fromEnvironment('firebase_config_ios');
// const String apnsKeyId = String.fromEnvironment('APNS_KEY_ID');
// const String apnsTeamId = String.fromEnvironment('APNS_TEAM_ID');
// const String apnsAuthKeyUrl = String.fromEnvironment('APNS_AUTH_KEY_URL');
//
// // General
// const String webUrl = String.fromEnvironment('WEB_URL');
// const String emailId = String.fromEnvironment('EMAIL_ID');
//
// // Splash screen
// const bool isSplashEnabled = bool.fromEnvironment('IS_SPLASH', defaultValue: false);
// const String splashBgUrl = String.fromEnvironment('SPLASH_BG');
// const String splashUrl = String.fromEnvironment('SPLASH');
// const String splashTagline = String.fromEnvironment('SPLASH_TAGLINE');
// const String splashTaglineColor = String.fromEnvironment('SPLASH_TAGLINE_COLOR');
// const String splashAnimation = String.fromEnvironment('SPLASH_ANIMATION');
// const int splashDuration = int.fromEnvironment('SPLASH_DURATION');
// const String splashBgColor = String.fromEnvironment('SPLASH_BG_COLOR');
//
// // Pull down
// const bool isPullDown = bool.fromEnvironment('IS_PULLDOWN', defaultValue: false);
//
// // Logo
// const String logoUrl = String.fromEnvironment('LOGO_URL');
//
// // Deep linking
// const bool isDeepLink = bool.fromEnvironment('IS_DEEPLINK', defaultValue: false);
//
// const bool isLoadIndicator = bool.fromEnvironment('IS_LOAD_IND', defaultValue: true);
//
// // Permissions
// const bool isCameraEnabled = bool.fromEnvironment('IS_CAMERA', defaultValue: false);
// const bool isLocationEnabled = bool.fromEnvironment('IS_LOCATION', defaultValue: false);
// const bool isMicEnabled = bool.fromEnvironment('IS_MIC', defaultValue: false);
// const bool isNotificationEnabled = bool.fromEnvironment('IS_NOTIFICATION', defaultValue: false);
// const bool isContactEnabled = bool.fromEnvironment('IS_CONTACT', defaultValue: false);
// const bool isBiometricEnabled = bool.fromEnvironment('IS_BIOMETRIC', defaultValue: false);
// const bool isCalendarEnabled = bool.fromEnvironment('IS_CALENDAR', defaultValue: false);
//
// // Push notification
// const bool pushNotify = bool.fromEnvironment('PUSH_NOTIFY', defaultValue: false);
//
// // Bottom menu
// const bool isBottomMenu = bool.fromEnvironment('IS_BOTTOMMENU', defaultValue: false);
// const String bottomMenuRaw = String.fromEnvironment('BOTTOMMENU_ITEMS');
// final List<Map<String, dynamic>> bottomMenuItems =
// (jsonDecode(bottomMenuRaw) as List)
//     .map((e) => Map<String, dynamic>.from(e))
//     .toList();
//
// const String bottomMenuBgColor = String.fromEnvironment('BOTTOMMENU_BG_COLOR');
// const String bottomMenuIconColor = String.fromEnvironment('BOTTOMMENU_ICON_COLOR');
// const String bottomMenuTextColor = String.fromEnvironment('BOTTOMMENU_TEXT_COLOR');
// const String bottomMenuActiveTabColor = String.fromEnvironment('BOTTOMMENU_ACTIVE_TAB_COLOR');
// const String bottomMenuIconPosition = String.fromEnvironment('BOTTOMMENU_ICON_POSITION', defaultValue: 'above');
// const String bottomMenuVisibleOn = String.fromEnvironment('BOTTOMMENU_VISIBLE_ON');
//
