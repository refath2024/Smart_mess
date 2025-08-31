import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// EmailJS service for sending registration status emails
/// This service sends emails through EmailJS API when users are accepted/rejected
class EmailJSService {
  // EmailJS Configuration - Replace with your actual EmailJS credentials
  static const String _serviceId = 'service_kf2633o'; // Replace with your EmailJS Service ID
  static const String _publicKey = 'WBHh31_fkD0fBMBoj'; // Replace with your EmailJS Public Key
  static const String _acceptanceTemplateId = 'template_uvpwgl7'; // Replace with your acceptance template ID
  static const String _rejectionTemplateId = 'template_8te3jxp'; // Replace with your rejection template ID
  
  static const String _emailJSUrl = 'https://api.emailjs.com/api/v1.0/email/send-form';

  /// Send acceptance email to user
  static Future<bool> sendAcceptanceEmail({
    required String userEmail,
    required String userName,
    required String userRank,
    required String baNumber,
  }) async {
    try {
      debugPrint('📧 Sending acceptance email to: $userEmail');
      debugPrint('📧 User details: Name=$userName, Rank=$userRank, BA=$baNumber');
      
      // Create form data for EmailJS
      final request = http.MultipartRequest('POST', Uri.parse(_emailJSUrl));
      
      // Add required fields
      request.fields['service_id'] = _serviceId;
      request.fields['template_id'] = _acceptanceTemplateId;
      request.fields['user_id'] = _publicKey;
      request.fields['email'] = userEmail;
      
      // Add template parameters
      request.fields['to_name'] = userName;
      request.fields['user_rank'] = userRank;
      request.fields['ba_number'] = baNumber;
      request.fields['app_name'] = 'Smart Mess Management System';
      request.fields['approval_date'] = DateTime.now().toString().split(' ')[0];
      request.fields['message'] = 'Congratulations! Your Smart Mess application has been approved.';
      request.fields['subject'] = 'Smart Mess Application Approved';

      debugPrint('📧 Sending request to EmailJS...');
      debugPrint('📧 Service ID: $_serviceId');
      debugPrint('📧 Template ID: $_acceptanceTemplateId');
      debugPrint('📧 Public Key: ${_publicKey.substring(0, 5)}...');

      final response = await request.send().then((streamedResponse) async {
        return await http.Response.fromStream(streamedResponse);
      });

      debugPrint('📧 Response Status Code: ${response.statusCode}');
      debugPrint('📧 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        debugPrint('✅ Acceptance email sent successfully to $userEmail');
        return true;
      } else {
        debugPrint('❌ Failed to send acceptance email. Status: ${response.statusCode}');
        debugPrint('❌ Response: ${response.body}');
        
        // Additional debugging for common errors
        if (response.statusCode == 400) {
          debugPrint('❌ Bad Request - Check template variables or template ID');
        } else if (response.statusCode == 401) {
          debugPrint('❌ Unauthorized - Check public key');
        } else if (response.statusCode == 404) {
          debugPrint('❌ Not Found - Check service ID or template ID');
        }
        
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error sending acceptance email: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      return false;
    }
  }

  /// Send rejection email to user
  static Future<bool> sendRejectionEmail({
    required String userEmail,
    required String userName,
    required String userRank,
    required String baNumber,
    String? rejectionReason,
  }) async {
    try {
      debugPrint('📧 Sending rejection email to: $userEmail');
      debugPrint('📧 User details: Name=$userName, Rank=$userRank, BA=$baNumber');
      debugPrint('📧 Rejection reason: ${rejectionReason ?? "Not specified"}');
      
      // Create form data for EmailJS
      final request = http.MultipartRequest('POST', Uri.parse(_emailJSUrl));
      
      // Add required fields
      request.fields['service_id'] = _serviceId;
      request.fields['template_id'] = _rejectionTemplateId;
      request.fields['user_id'] = _publicKey;
      request.fields['email'] = userEmail;
      
      // Add template parameters
      request.fields['to_name'] = userName;
      request.fields['user_rank'] = userRank;
      request.fields['ba_number'] = baNumber;
      request.fields['app_name'] = 'Smart Mess Management System';
      request.fields['rejection_date'] = DateTime.now().toString().split(' ')[0];
      request.fields['rejection_reason'] = rejectionReason ?? 'Please contact administration for more details.';
      request.fields['message'] = 'We regret to inform you that your Smart Mess application has been rejected.';
      request.fields['subject'] = 'Smart Mess Application Status';

      debugPrint('📧 Sending rejection request to EmailJS...');
      debugPrint('📧 Service ID: $_serviceId');
      debugPrint('📧 Template ID: $_rejectionTemplateId');

      final response = await request.send().then((streamedResponse) async {
        return await http.Response.fromStream(streamedResponse);
      });

      debugPrint('📧 Response Status Code: ${response.statusCode}');
      debugPrint('📧 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        debugPrint('✅ Rejection email sent successfully to $userEmail');
        return true;
      } else {
        debugPrint('❌ Failed to send rejection email. Status: ${response.statusCode}');
        debugPrint('❌ Response: ${response.body}');
        
        // Additional debugging for common errors
        if (response.statusCode == 400) {
          debugPrint('❌ Bad Request - Check template variables or template ID');
        } else if (response.statusCode == 401) {
          debugPrint('❌ Unauthorized - Check public key');
        } else if (response.statusCode == 404) {
          debugPrint('❌ Not Found - Check service ID or template ID');
        }
        
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error sending rejection email: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      return false;
    }
  }

  /// Test EmailJS configuration
  static Future<bool> testEmailConfiguration() async {
    try {
      debugPrint('🧪 Testing EmailJS configuration...');
      
      // Create form data for EmailJS test
      final request = http.MultipartRequest('POST', Uri.parse(_emailJSUrl));
      
      // Add required fields
      request.fields['service_id'] = _serviceId;
      request.fields['template_id'] = _acceptanceTemplateId;
      request.fields['user_id'] = _publicKey;
      request.fields['email'] = 'test@example.com';
      
      // Add template parameters
      request.fields['to_name'] = 'Test User';
      request.fields['user_rank'] = 'Test Rank';
      request.fields['ba_number'] = 'TEST123';
      request.fields['app_name'] = 'Smart Mess Management System';
      request.fields['approval_date'] = DateTime.now().toString().split(' ')[0];

      final response = await request.send().then((streamedResponse) async {
        return await http.Response.fromStream(streamedResponse);
      });

      if (response.statusCode == 200) {
        debugPrint('✅ EmailJS configuration test successful');
        return true;
      } else {
        debugPrint('❌ EmailJS configuration test failed. Status: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ EmailJS configuration test error: $e');
      return false;
    }
  }

  /// Check if EmailJS is properly configured
  static bool isConfigured() {
    return _serviceId != 'service_your_service_id' && 
           _publicKey != 'your_public_key' &&
           _acceptanceTemplateId != 'template_acceptance' &&
           _rejectionTemplateId != 'template_rejection';
  }

  /// Simple test method to verify EmailJS setup
  static Future<void> debugEmailService() async {
    debugPrint('🔍 === EmailJS Debug Information ===');
    debugPrint('🔍 Service ID: $_serviceId');
    debugPrint('🔍 Public Key: ${_publicKey.substring(0, 5)}...');
    debugPrint('🔍 Acceptance Template: $_acceptanceTemplateId');
    debugPrint('🔍 Rejection Template: $_rejectionTemplateId');
    debugPrint('🔍 EmailJS URL: $_emailJSUrl');
    debugPrint('🔍 Configuration Status: ${isConfigured() ? "✅ Configured" : "❌ Not Configured"}');
    debugPrint('🔍 === End Debug Information ===');
  }
}
