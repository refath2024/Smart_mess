# EmailJS Setup Guide for Smart Mess

## 📧 **Step-by-Step EmailJS Configuration**

### **Step 1: Create EmailJS Account**
1. Go to [EmailJS.com](https://www.emailjs.com/)
2. Click "Sign Up" and create a free account
3. Verify your email address

### **Step 2: Add Email Service**
1. In your EmailJS dashboard, click "Email Services"
2. Click "Add New Service"
3. Choose your email provider:
   - **Gmail** (Recommended for testing)
   - **Outlook**
   - **Yahoo**
   - Or other SMTP services
4. Follow the authentication steps for your chosen provider
5. **Copy the Service ID** (e.g., `service_abc123`)

### **Step 3: Create Email Templates**

#### **Acceptance Template:**
1. Go to "Email Templates" in your dashboard
2. Click "Create New Template"
3. Template Name: `User Acceptance Notification`
4. **Template ID**: Copy this (e.g., `template_acceptance_xyz`)

**Template Content:**
```
Subject: 🎉 Smart Mess Application Approved - Welcome!

Dear {{user_rank}} {{to_name}},

Congratulations! Your Smart Mess application has been APPROVED.

Application Details:
• Name: {{to_name}}
• Rank: {{user_rank}}
• BA Number: {{ba_number}}
• Email: {{to_email}}
• Status: APPROVED ✅
• Approval Date: {{approval_date}}

You can now access the {{app_name}} with your registered credentials.

What's next?
1. Log in to the Smart Mess app
2. Complete your profile setup
3. Start using mess management features

If you have any questions, please contact our support team.

Welcome to Smart Mess!

Best regards,
Smart Mess Administration Team

---
This is an automated message from {{app_name}}.
```

#### **Rejection Template:**
1. Create another template
2. Template Name: `User Rejection Notification`
3. **Template ID**: Copy this (e.g., `template_rejection_xyz`)

**Template Content:**
```
Subject: 📋 Smart Mess Application Status Update

Dear {{user_rank}} {{to_name}},

Thank you for your interest in the Smart Mess Management System.

Application Details:
• Name: {{to_name}}
• Rank: {{user_rank}}
• BA Number: {{ba_number}}
• Email: {{to_email}}
• Status: NOT APPROVED ❌
• Review Date: {{rejection_date}}

Unfortunately, your application could not be approved at this time.

Reason: {{rejection_reason}}

What you can do:
1. Contact the administration for specific feedback
2. Resubmit your application with updated information
3. Reach out to our support team for assistance

We encourage you to address any issues and reapply when ready.

For questions or clarification, please contact our support team.

Best regards,
Smart Mess Administration Team

---
This is an automated message from {{app_name}}.
```

### **Step 4: Get Public Key**
1. In EmailJS dashboard, go to "Account" → "General"
2. **Copy your Public Key** (e.g., `user_abc123xyz`)

### **Step 5: Update Your App Configuration**
Open `lib/services/emailjs_service.dart` and replace:

```dart
// Replace these with your actual EmailJS credentials:
static const String _serviceId = 'YOUR_ACTUAL_SERVICE_ID';
static const String _publicKey = 'YOUR_ACTUAL_PUBLIC_KEY';
static const String _acceptanceTemplateId = 'YOUR_ACCEPTANCE_TEMPLATE_ID';
static const String _rejectionTemplateId = 'YOUR_REJECTION_TEMPLATE_ID';
```

**Example:**
```dart
static const String _serviceId = 'service_abc123';
static const String _publicKey = 'user_abc123xyz';
static const String _acceptanceTemplateId = 'template_acceptance_xyz';
static const String _rejectionTemplateId = 'template_rejection_xyz';
```

### **Step 6: Test Email Configuration**

#### **Add Test Button to Admin Screen** (Optional):
Add this to your admin pending IDs screen for testing:

```dart
// Add this as a floating action button or button
FloatingActionButton(
  onPressed: () async {
    final result = await EmailJSService.testEmailConfiguration();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result ? '✅ EmailJS Test Successful' : '❌ EmailJS Test Failed'),
        backgroundColor: result ? Colors.green : Colors.red,
      ),
    );
  },
  child: Icon(Icons.email_outlined),
  tooltip: 'Test EmailJS',
)
```

### **Step 7: EmailJS Free Tier Limits**
- **200 emails/month** (Free tier)
- **2 MB attachment limit**
- **No daily sending limit**
- **Upgrade available** for higher limits

### **Step 8: Security Considerations**
- ✅ Public Key is safe to include in client-side code
- ✅ EmailJS handles authentication securely
- ✅ No server-side setup required
- ⚠️ Monitor usage to avoid exceeding limits

## 🧪 **Testing Your Setup**

### **Manual Test:**
1. Update the credentials in `emailjs_service.dart`
2. Run your Flutter app
3. Go to Admin → Pending IDs
4. Accept or reject a test user
5. Check the debug console for email sending logs
6. Verify email is received

### **Debug Output to Look For:**
```
📧 Sending acceptance email to: user@example.com
✅ Acceptance email sent successfully to user@example.com
```

### **Troubleshooting:**
- **404 Error**: Check Service ID and Template IDs
- **403 Error**: Check Public Key
- **Email not received**: Check spam folder, verify email address
- **Template errors**: Ensure all variables are correctly named

## 🎯 **Template Variables Used**

Your templates can use these variables:
- `{{to_email}}` - User's email address
- `{{to_name}}` - User's full name
- `{{user_rank}}` - User's military rank
- `{{ba_number}}` - User's BA number
- `{{app_name}}` - Application name (Smart Mess Management System)
- `{{approval_date}}` - Date of approval (acceptance emails)
- `{{rejection_date}}` - Date of rejection (rejection emails)
- `{{rejection_reason}}` - Reason for rejection (rejection emails)

## ✅ **Setup Checklist**

- [ ] EmailJS account created
- [ ] Email service configured (Gmail/Outlook)
- [ ] Acceptance template created with correct variables
- [ ] Rejection template created with correct variables
- [ ] Service ID copied to app
- [ ] Public Key copied to app
- [ ] Template IDs copied to app
- [ ] App tested with real email addresses
- [ ] Email delivery confirmed

Once setup is complete, users will automatically receive professional email notifications when their applications are processed!
