// Test file to verify Gemini service enhancements
import 'package:flutter/material.dart';
import 'gemini_service.dart';

class GeminiTestScreen extends StatefulWidget {
  @override
  _GeminiTestScreenState createState() => _GeminiTestScreenState();
}

class _GeminiTestScreenState extends State<GeminiTestScreen> {
  final TextEditingController _controller = TextEditingController();
  String _response = '';
  bool _isLoading = false;

  Future<void> _testGeminiService() async {
    if (_controller.text.trim().isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _response = '';
    });

    try {
      final response = await GeminiService.getReply(_controller.text);
      setState(() {
        _response = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _response = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gemini Service Test'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Enter your message',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _testGeminiService,
              child: _isLoading 
                ? CircularProgressIndicator() 
                : Text('Send Message'),
            ),
            SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _response.isEmpty 
                      ? 'Response will appear here...'
                      : _response,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Test cases:\n'
              '• Type "hello" to test fallback responses\n'
              '• Type "menu" to test offline capabilities\n'
              '• Send multiple requests quickly to test rate limiting\n'
              '• Complex queries will use Gemini API (if quota available)',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
