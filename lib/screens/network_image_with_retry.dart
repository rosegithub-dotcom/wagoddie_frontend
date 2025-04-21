// screens/network_image_with_retry.dart
import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;

class NetworkImageWithRetry extends StatefulWidget {
  final String imageUrl;
  final double height;
  final double width;
  final BoxFit fit;
  final Color? backgroundColor;
  final Widget Function(BuildContext, dynamic)? errorWidget;
  final bool debugMode;

  const NetworkImageWithRetry({
    Key? key,
    required this.imageUrl,
    this.height = 120,
    this.width = double.infinity,
    this.fit = BoxFit.cover,
    this.backgroundColor,
    this.errorWidget,
    this.debugMode = false,
  }) : super(key: key);

  @override
  _NetworkImageWithRetryState createState() => _NetworkImageWithRetryState();
}

class _NetworkImageWithRetryState extends State<NetworkImageWithRetry> {
  bool _hasError = false;
  String _errorMessage = '';
  int _retryCount = 0;
  final int _maxRetries = 2;
  
  @override
  void initState() {
    super.initState();
    if (widget.debugMode) {
      _checkImageAvailability();
    }
  }

  Future<void> _checkImageAvailability() async {
    if (widget.imageUrl.isEmpty) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Empty URL';
      });
      return;
    }

    try {
      print('Checking image availability: ${widget.imageUrl}');
      final response = await http.head(Uri.parse(widget.imageUrl));
      print('Image HEAD response: ${response.statusCode} - ${response.headers}');
      
      if (response.statusCode != 200) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Status ${response.statusCode}';
        });
      }
    } catch (e) {
      print('Error checking image: $e');
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  void _retryLoading() {
    if (_retryCount < _maxRetries) {
      setState(() {
        _hasError = false;
        _errorMessage = '';
        _retryCount++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrl.isEmpty) {
      return _buildPlaceholder('No image URL');
    }

    return Container(
      height: widget.height,
      width: widget.width,
      color: widget.backgroundColor ?? Colors.grey[200],
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            widget.imageUrl,
            fit: widget.fit,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) {
                return child;
              }
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          (loadingProgress.expectedTotalBytes ?? 1)
                      : null,
                  color: Colors.orange,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              print('Image load error for ${widget.imageUrl}: $error');
              _hasError = true;
              _errorMessage = error.toString();
              
              if (widget.errorWidget != null) {
                return widget.errorWidget!(context, error);
              }
              
              return _buildErrorWidget(error);
            },
          ),
          if (_hasError && widget.debugMode)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black54,
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Text(
                  'Error: $_errorMessage',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(dynamic error) {
    return GestureDetector(
      onTap: _retryLoading,
      child: Container(
        color: Colors.grey[300],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported, color: Colors.grey[500]),
              SizedBox(height: 4),
              Text(
                "Tap to retry",
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(String message) {
    return Container(
      height: widget.height,
      width: widget.width,
      color: widget.backgroundColor ?? Colors.grey[300],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, color: Colors.grey[500]),
            SizedBox(height: 4),
            Text(
              message,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
