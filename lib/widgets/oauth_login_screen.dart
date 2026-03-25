// lib/widgets/oauth_login_screen.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import '../services/broker_manager.dart';

class OAuthLoginScreen extends StatefulWidget {
  final String brokerId;
  final String authUrl;
  final String redirectUri;
  
  const OAuthLoginScreen({
    Key? key,
    required this.brokerId,
    required this.authUrl,
    required this.redirectUri,
  }) : super(key: key);

  @override
  _OAuthLoginScreenState createState() => _OAuthLoginScreenState();
}

class _OAuthLoginScreenState extends State<OAuthLoginScreen> {
  late WebViewController _controller;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _initWebView();
  }
  
  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (url) {
            setState(() => _isLoading = false);
            _checkForCallback(url);
          },
          onNavigationRequest: (request) {
            if (request.url.startsWith(widget.redirectUri)) {
              _handleCallback(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.authUrl));
  }
  
  void _checkForCallback(String url) {
    if (url.startsWith(widget.redirectUri)) {
      _handleCallback(url);
    }
  }
  
  void _handleCallback(String url) {
    // Parse the callback URL to extract code or token
    final uri = Uri.parse(url);
    final code = uri.queryParameters['code'];
    final error = uri.queryParameters['error'];
    
    if (error != null) {
      Navigator.pop(context, {'error': error});
      return;
    }
    
    if (code != null) {
      // Exchange code for token (this would be done by the broker's login method)
      // For now, just return the code
      Navigator.pop(context, {'code': code});
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login to ${widget.brokerId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
