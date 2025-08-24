import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _apiKey = "AIzaSyCffTQ0xc1dzBYKrvdIAAPjPqDV5_gHgkw";
  static const String _apiUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_apiKey";
  
  // Track last request time to implement simple rate limiting
  static DateTime? _lastRequestTime;
  static const Duration _minRequestInterval = Duration(seconds: 2);

  static Future<String> getReply(String prompt) async {
    // Check for common questions and provide offline fallback responses first
    final fallbackResponse = _getFallbackResponse(prompt.toLowerCase());
    
    // If we have a good fallback response for common questions, use it immediately
    if (fallbackResponse != null) {
      print("GeminiService: Using fallback response for: $prompt");
      return "🤖 $fallbackResponse";
    }
    
    try {
      // Check if we need to wait before making the request
      if (_lastRequestTime != null) {
        final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!);
        if (timeSinceLastRequest < _minRequestInterval) {
          final waitTime = _minRequestInterval - timeSinceLastRequest;
          print("GeminiService: Waiting ${waitTime.inMilliseconds}ms before next request");
          await Future.delayed(waitTime);
        }
      }
      
      _lastRequestTime = DateTime.now();
      return await _makeApiCall(prompt);
    } catch (e) {
      print("Primary API call failed: $e");
      
      // For complex questions when API fails, provide helpful guidance
      return "🔄 I'm currently unable to process complex questions due to high API usage. However, I can help with:\n\n"
             "• Menu voting and schedules\n"
             "• Bill and payment information\n"
             "• How to file complaints\n"
             "• Admin features and settings\n\n"
             "Try asking simpler questions like 'help', 'menu', 'bill', or 'vote' for immediate assistance!";
    }
  }

  static Future<String> _makeApiCall(String prompt) async {
    final requestBody = {
  "contents": [
    {
      "parts": [
        {
          "text": """
You are a helpful assistant for the Smart Mess Manager app. You can answer questions related to:

- Meal schedule
- Bill details
- Voting system
- How to edit the menu
- Admin features
- Feedback system
- Rules for dining
- Contact info for mess in-charge
- How users can log complaints
- How mess members can join/leave
- How to update meal info
- How to pay bills


User: $prompt
"""
        }
      ]
    }
  ]
};

    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {"Content-Type": "application/json"},
      body: json.encode(requestBody),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print("Gemini API Response: $data");
      try {
        return data["candidates"][0]["content"]["parts"][0]["text"] ?? "No response text";
      } catch (e) {
        print("Parse error: $e");
        return "Sorry, I couldn't understand the response.";
      }
    } else if (response.statusCode == 429) {
      // Handle rate limiting specifically - throw exception to trigger fallback
      print("Gemini API Rate Limit: ${response.body}");
      throw Exception("Rate limit exceeded");
    } else {
      print("Gemini API Error: ${response.body}");
      
      // Try to parse error for better user messaging
      try {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['error']['message'] ?? 'Unknown error';
        
        if (errorMessage.contains('Quota exceeded') || errorMessage.contains('RATE_LIMIT_EXCEEDED')) {
          throw Exception("Quota exceeded");
        } else if (errorMessage.contains('API key')) {
          throw Exception("API key error");
        } else {
          throw Exception("API error: $errorMessage");
        }
      } catch (e) {
        throw Exception("API communication error");
      }
    }
  }

  static String? _getFallbackResponse(String prompt) {
    // Common questions and their offline responses
    final fallbacks = {
      'hello': 'Hello! I\'m the Smart Mess Assistant. How can I help you today?\n\nI can assist with:\n• Menu voting and schedules\n• Bill and payment details\n• Filing complaints\n• Admin features\n• Meal timings',
      'hi': 'Hi there! I can help you with meal schedules, voting, bills, and more. What would you like to know?',
      'help': 'I can assist you with:\n\n🍽️ **Meal & Menu**\n• View and vote for weekly menu\n• Check meal schedules and timings\n\n💰 **Billing & Payments**\n• View your monthly bill\n• Check payment history\n• Payment methods available\n\n📝 **Feedback & Complaints**\n• File complaints or suggestions\n• Contact mess committee\n\n⚙️ **Admin Features**\n• User management (for admins)\n• Menu configuration\n• Statistics and reports\n\nJust ask me about any of these topics!',
      'menu': '🍽️ **Menu & Voting Information**\n\nYou can view and vote for the weekly menu in the Menu Voting section. Here\'s how:\n\n1. Go to Menu Voting from the main screen\n2. View the 3 menu options for the week\n3. Vote for your preferred option\n4. You can change your vote once per week\n5. Voting is available on Sundays only\n\nThe menu is updated weekly based on member preferences!',
      'vote': '🗳️ **How to Vote for Meals**\n\n1. Navigate to "Menu Voting" section\n2. You can vote once per week (Sundays only)\n3. Choose from 3 available menu options\n4. If you want to change your vote, you\'ll get a warning but can proceed\n5. Admin can override voting restrictions if needed\n\nYour vote helps determine the weekly menu for everyone!',
      'voting': '🗳️ **How to Vote for Meals**\n\n1. Navigate to "Menu Voting" section\n2. You can vote once per week (Sundays only)\n3. Choose from 3 available menu options\n4. If you want to change your vote, you\'ll get a warning but can proceed\n5. Admin can override voting restrictions if needed\n\nYour vote helps determine the weekly menu for everyone!',
      'bill': '💰 **Bill Information**\n\nYour bill details are available in the Billing section:\n\n• View monthly charges\n• Check payment history\n• See outstanding amounts\n• Download bill receipts\n\nTo access: Go to main menu → Billing section',
      'payment': '💳 **Payment Options**\n\nYou can make payments through:\n\n• Mobile banking (bKash, Nagad, etc.)\n• Credit/Debit cards\n• Cash payments to mess admin\n• Bank transfers\n\nCheck the Payment section in the app for current payment methods and instructions.',
      'complaint': '📝 **File a Complaint**\n\nTo report issues or give feedback:\n\n1. Go to "Feedback" section in the app\n2. Select complaint type\n3. Describe your concern clearly\n4. Submit the form\n\nYour complaints will be forwarded to the mess committee for review and action.',
      'feedback': '📝 **Give Feedback**\n\nTo share suggestions or report issues:\n\n1. Go to "Feedback" section in the app\n2. Choose feedback type\n3. Write your message\n4. Submit for review\n\nWe value your input to improve mess services!',
      'schedule': '⏰ **Meal Schedule**\n\nTypical meal timings:\n\n🌅 **Breakfast**: 7:00 AM - 9:00 AM\n🌞 **Lunch**: 12:00 PM - 2:00 PM\n🌙 **Dinner**: 7:00 PM - 9:00 PM\n\nNote: Exact timings may vary. Check the main menu for current schedules.',
      'admin': '⚙️ **Admin Features**\n\nAdmin panel includes:\n\n• User management and approval\n• Menu configuration (3 weekly options)\n• Billing and payment tracking\n• Voting statistics and reports\n• Notification management\n• Inventory tracking\n\nContact your mess administrator for admin access.',
      'time': '⏰ **Current Information**\n\nFor real-time meal schedules and timings, please check the main dashboard of the app. Timings may vary based on:\n\n• Daily operations\n• Special events\n• Kitchen schedule\n• Holiday adjustments',
      'contact': '📞 **Contact Information**\n\nTo reach the mess management:\n\n• Use the Feedback section in the app\n• Contact mess administrator directly\n• Submit complaints through the app\n• Check notice board for announcements\n\nFor urgent matters, contact the mess in-charge directly.',
    };

    // Check for exact matches first
    for (String key in fallbacks.keys) {
      if (prompt.contains(key)) {
        return fallbacks[key];
      }
    }
    
    // Check for partial matches for complex queries
    if (prompt.contains('how') && (prompt.contains('vote') || prompt.contains('menu'))) {
      return fallbacks['vote'];
    }
    
    if (prompt.contains('what') && prompt.contains('time')) {
      return fallbacks['schedule'];
    }
    
    if (prompt.contains('problem') || prompt.contains('issue')) {
      return fallbacks['complaint'];
    }
    
    return null;
  }
}
