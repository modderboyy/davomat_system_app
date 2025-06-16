// --- webview_page.dart ---
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // Internet tekshirish uchun
import 'dart:async';

class InAppWebViewPage extends StatefulWidget {
  final String url;
  final String title;
  final String currentLanguage; // "Internet yo'q" tarjimasi uchun

  const InAppWebViewPage({
    Key? key,
    required this.url,
    required this.title,
    required this.currentLanguage,
  }) : super(key: key);

  @override
  _InAppWebViewPageState createState() => _InAppWebViewPageState();
}

class _InAppWebViewPageState extends State<InAppWebViewPage> {
  late final WebViewController _controller;
  bool _isLoadingPage = true;
  bool _hasInternet = true;
  StreamSubscription? _connectivitySubscription;

  // Bu sahifa uchun sodda tarjimalar
  String _translateWebView(String key) {
    final Map<String, Map<String, String>> localizedStrings = {
      'en': {
        'no_internet_connection': 'No Internet Connection',
        'loading': 'Loading...',
        'retry': 'Retry'
      },
      'uz': {
        'no_internet_connection': 'Internet aloqasi yo\'q',
        'loading': 'Yuklanmoqda...',
        'retry': 'Qaytadan'
      },
      'ru': {
        'no_internet_connection': 'Нет подключения к Интернету',
        'loading': 'Загрузка...',
        'retry': 'Повторить'
      },
    };
    return localizedStrings[widget.currentLanguage]?[key] ??
        localizedStrings['uz']![key]!;
  }

  @override
  void initState() {
    super.initState();
    _checkInitialConnectivity();

    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      _updateConnectionStatus(results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.wifi));
    });

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000)) // Shaffof fon
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) setState(() => _isLoadingPage = true);
          },
          onPageFinished: (String url) {
            if (mounted) setState(() => _isLoadingPage = false);
          },
          onWebResourceError: (WebResourceError error) {
            if (mounted) {
              setState(() => _isLoadingPage = false);
              print(
                  "WebResourceError: ${error.description}, Code: ${error.errorCode}, Type: ${error.errorType}");
              // Agar ma'lum bir xatolik turlarini alohida ko'rsatmoqchi bo'lsangiz:
              // if (error.errorCode == -2) { // net::ERR_INTERNET_DISCONNECTED
              //   setState(() => _hasInternet = false);
              // }
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            // Agar kerak bo'lsa, navigatsiyani cheklash uchun logikani shu yerga qo'shishingiz mumkin
            return NavigationDecision.navigate;
          },
        ),
      );

    if (_hasInternet) {
      _controller.loadRequest(Uri.parse(widget.url));
    }
  }

  Future<void> _checkInitialConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    _updateConnectionStatus(
        connectivityResult.contains(ConnectivityResult.mobile) ||
            connectivityResult.contains(ConnectivityResult.wifi));
  }

  void _updateConnectionStatus(bool isConnected) {
    if (mounted) {
      final bool hadInternetBefore = _hasInternet;
      setState(() {
        _hasInternet = isConnected;
      });
      if (_hasInternet &&
          !hadInternetBefore &&
          _controller.currentUrl() == null) {
        // Agar internet qayta tiklansa va sahifa yuklanmagan bo'lsa, uni yuklang.
        _controller.loadRequest(Uri.parse(widget.url));
      }
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        elevation: 1.0,
        actions: [
          if (_isLoadingPage && _hasInternet)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).appBarTheme.foregroundColor ??
                            theme.colorScheme.onPrimary),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _hasInternet
          ? WebViewWidget(controller: _controller)
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off, size: 60, color: Colors.grey[700]),
                  const SizedBox(height: 16),
                  Text(
                    _translateWebView('no_internet_connection'),
                    style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                      icon: Icon(Icons.refresh),
                      label: Text(_translateWebView("retry")),
                      onPressed: () async {
                        if (mounted) setState(() => _isLoadingPage = true);
                        await _checkInitialConnectivity(); // Qayta tekshirish
                        if (_hasInternet) {
                          // Agar internet bo'lsa
                          _controller.loadRequest(Uri.parse(widget.url));
                        } else {
                          // Agar hali ham internet yo'q bo'lsa
                          if (mounted) setState(() => _isLoadingPage = false);
                        }
                      })
                ],
              ),
            ),
    );
  }
}
