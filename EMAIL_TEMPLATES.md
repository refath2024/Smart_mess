# Email Template Examples for EmailJS

## 📧 **Template 1: User Acceptance Email**

### **Template Settings:**
- **Template Name**: `Smart Mess - User Acceptance`
- **Template ID**: `template_acceptance` (replace in code)
- **From Name**: `Smart Mess Admin`
- **Reply To**: `admin@smartmess.com` (your admin email)

### **Subject Line:**
```
🎉 Smart Mess Application Approved - Welcome Aboard!
```

### **Email Body (HTML):**
```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <style>
        .container { max-width: 600px; margin: 0 auto; font-family: Arial, sans-serif; }
        .header { background: #2E7D32; color: white; padding: 20px; text-align: center; }
        .content { padding: 20px; background: #f9f9f9; }
        .details { background: white; padding: 15px; border-radius: 5px; margin: 10px 0; }
        .footer { background: #424242; color: white; padding: 15px; text-align: center; font-size: 12px; }
        .success { color: #2E7D32; font-weight: bold; }
        .icon { font-size: 48px; margin: 10px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="icon">🎉</div>
            <h1>Application Approved!</h1>
            <p>Welcome to Smart Mess Management System</p>
        </div>
        
        <div class="content">
            <h2>Dear {{user_rank}} {{to_name}},</h2>
            
            <p>Congratulations! Your Smart Mess application has been <span class="success">APPROVED</span>.</p>
            
            <div class="details">
                <h3>📋 Application Details:</h3>
                <ul>
                    <li><strong>Name:</strong> {{to_name}}</li>
                    <li><strong>Rank:</strong> {{user_rank}}</li>
                    <li><strong>BA Number:</strong> {{ba_number}}</li>
                    <li><strong>Email:</strong> {{to_email}}</li>
                    <li><strong>Status:</strong> <span class="success">APPROVED ✅</span></li>
                    <li><strong>Approval Date:</strong> {{approval_date}}</li>
                </ul>
            </div>
            
            <div class="details">
                <h3>🚀 What's Next?</h3>
                <ol>
                    <li>Log in to the Smart Mess app with your registered credentials</li>
                    <li>Complete your profile setup</li>
                    <li>Start using mess management features</li>
                    <li>Access menu voting, bill tracking, and more!</li>
                </ol>
            </div>
            
            <div class="details">
                <h3>🔗 Quick Actions:</h3>
                <p>
                    <a href="#" style="background: #2E7D32; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">Login to App</a>
                    <a href="#" style="background: #1976D2; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; margin-left: 10px;">User Guide</a>
                </p>
            </div>
            
            <p>If you have any questions, please contact our support team.</p>
            
            <p><strong>Welcome to {{app_name}}!</strong></p>
            
            <p>Best regards,<br>
            Smart Mess Administration Team</p>
        </div>
        
        <div class="footer">
            <p>This is an automated message from {{app_name}}.</p>
            <p>© 2025 Smart Mess Management System. All rights reserved.</p>
        </div>
    </div>
</body>
</html>
```

---

## 📧 **Template 2: User Rejection Email**

### **Template Settings:**
- **Template Name**: `Smart Mess - User Rejection`
- **Template ID**: `template_rejection` (replace in code)
- **From Name**: `Smart Mess Admin`
- **Reply To**: `admin@smartmess.com` (your admin email)

### **Subject Line:**
```
📋 Smart Mess Application Status Update
```

### **Email Body (HTML):**
```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <style>
        .container { max-width: 600px; margin: 0 auto; font-family: Arial, sans-serif; }
        .header { background: #D32F2F; color: white; padding: 20px; text-align: center; }
        .content { padding: 20px; background: #f9f9f9; }
        .details { background: white; padding: 15px; border-radius: 5px; margin: 10px 0; }
        .footer { background: #424242; color: white; padding: 15px; text-align: center; font-size: 12px; }
        .rejected { color: #D32F2F; font-weight: bold; }
        .action { color: #1976D2; font-weight: bold; }
        .icon { font-size: 48px; margin: 10px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="icon">📋</div>
            <h1>Application Status Update</h1>
            <p>Smart Mess Management System</p>
        </div>
        
        <div class="content">
            <h2>Dear {{user_rank}} {{to_name}},</h2>
            
            <p>Thank you for your interest in the Smart Mess Management System.</p>
            
            <div class="details">
                <h3>📋 Application Details:</h3>
                <ul>
                    <li><strong>Name:</strong> {{to_name}}</li>
                    <li><strong>Rank:</strong> {{user_rank}}</li>
                    <li><strong>BA Number:</strong> {{ba_number}}</li>
                    <li><strong>Email:</strong> {{to_email}}</li>
                    <li><strong>Status:</strong> <span class="rejected">NOT APPROVED ❌</span></li>
                    <li><strong>Review Date:</strong> {{rejection_date}}</li>
                </ul>
            </div>
            
            <div class="details">
                <h3>📝 Reason:</h3>
                <p>{{rejection_reason}}</p>
            </div>
            
            <div class="details">
                <h3>🔄 What You Can Do:</h3>
                <ol>
                    <li>Contact the administration for specific feedback</li>
                    <li>Review and update your application information</li>
                    <li>Resubmit your application when requirements are met</li>
                    <li>Reach out to our support team for assistance</li>
                </ol>
            </div>
            
            <div class="details">
                <h3>📞 Need Help?</h3>
                <p>
                    <a href="#" style="background: #1976D2; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">Contact Support</a>
                    <a href="#" style="background: #FF9800; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; margin-left: 10px;">Reapply</a>
                </p>
            </div>
            
            <p>We encourage you to address any issues and reapply when ready.</p>
            
            <p>For questions or clarification, please contact our support team.</p>
            
            <p>Best regards,<br>
            Smart Mess Administration Team</p>
        </div>
        
        <div class="footer">
            <p>This is an automated message from {{app_name}}.</p>
            <p>© 2025 Smart Mess Management System. All rights reserved.</p>
        </div>
    </div>
</body>
</html>
```

---

## 📱 **Text-Only Versions (Fallback)**

### **Acceptance Email (Text):**
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

Welcome to Smart Mess!

Best regards,
Smart Mess Administration Team

---
This is an automated message from {{app_name}}.
```

### **Rejection Email (Text):**
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

Reason: {{rejection_reason}}

What you can do:
1. Contact administration for feedback
2. Update your application information
3. Resubmit when requirements are met
4. Contact support for assistance

Best regards,
Smart Mess Administration Team

---
This is an automated message from {{app_name}}.
```

## 🔧 **Template Variables Reference**

| Variable | Description | Example |
|----------|-------------|---------|
| `{{to_email}}` | User's email address | `user@example.com` |
| `{{to_name}}` | User's full name | `John Smith` |
| `{{user_rank}}` | Military rank | `Captain` |
| `{{ba_number}}` | BA/Service number | `BA123456` |
| `{{app_name}}` | Application name | `Smart Mess Management System` |
| `{{approval_date}}` | Date of approval | `2025-08-31` |
| `{{rejection_date}}` | Date of rejection | `2025-08-31` |
| `{{rejection_reason}}` | Reason for rejection | `Incomplete documentation` |

## 💡 **Tips for Better Email Templates**

1. **Use HTML for rich formatting** but provide text fallback
2. **Keep subject lines under 50 characters** for mobile compatibility
3. **Include branding** (colors, logos) for professional appearance
4. **Make buttons/links obvious** with contrasting colors
5. **Test templates** with real data before going live
6. **Mobile-responsive design** for users checking email on phones

Copy these templates to your EmailJS dashboard and customize as needed!
