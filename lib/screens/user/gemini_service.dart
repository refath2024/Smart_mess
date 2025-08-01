import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _apiKey = "AIzaSyCffTQ0xc1dzBYKrvdIAAPjPqDV5_gHgkw";
  static const String _apiUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_apiKey";

  static Future<String> getReply(String prompt) async {
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
    } else {
      print("Gemini API Error: ${response.body}");
      return "Sorry, I'm having trouble understanding right now. Please try again later.";
    }
  }
}
