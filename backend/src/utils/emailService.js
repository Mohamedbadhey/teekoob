const logger = require('./logger');

/**
 * Email Service for sending emails
 * Supports SMTP configuration via environment variables
 * Falls back to console logging in development if not configured
 */

class EmailService {
  constructor() {
    this.isConfigured = false;
    this.useResend = false;
    this.resendClient = null;
    this._initializeTransporter();
  }

  _initializeTransporter() {
    // Resend-only email provider
    const resendApiKey = process.env.RESEND_API_KEY;
    const resendFrom = process.env.RESEND_FROM || process.env.EMAIL_FROM || 'onboarding@resend.dev';
    if (resendApiKey) {
      try {
        const { Resend } = require('resend');
        this.resendClient = new Resend(resendApiKey);
        this.useResend = true;
        this.isConfigured = true;
        console.log('📧 Email Service: Using Resend as provider');
        logger.info('✅ Email service configured with Resend', {
          from: resendFrom
        });
        return;
      } catch (error) {
        logger.error('❌ Failed to initialize Resend client:', error);
        console.error('❌ Resend initialization error:', error.message);
        this.useResend = false;
        this.resendClient = null;
        this.isConfigured = false;
        return;
      }
    }

    // If we reach here, Resend is not configured
    console.log('📧 Email Service Configuration Check:');
    console.log('  - RESEND_API_KEY:', resendApiKey ? '✅ SET' : '❌ MISSING');
    logger.warn('⚠️ Email service not configured. Set RESEND_API_KEY to enable email sending.');
    this.isConfigured = false;
  }

  /**
   * Send password reset code email
   * @param {string} email - Recipient email
   * @param {string} code - 6-digit verification code
   * @returns {Promise<boolean>} - Success status
   */
  async sendPasswordResetCode(email, code) {
    // Get app name and expiry time from environment
    const appName = process.env.APP_NAME || 'Bookdoon';
    const expiryMinutes = parseInt(process.env.RESET_CODE_EXPIRY_MINUTES || '10', 10);
    
    const subject = `Password Reset Code - ${appName}`;
    const html = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Password Reset Code</title>
      </head>
      <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
        <div style="background-color: #f4f4f4; padding: 20px; border-radius: 10px;">
          <h1 style="color: #2c3e50; text-align: center;">Password Reset Request</h1>
          
          <p>Hello,</p>
          
          <p>You have requested to reset your password for your ${appName} account. Please use the following verification code to reset your password:</p>
          
          <div style="background-color: #ffffff; border: 2px dashed #3498db; border-radius: 5px; padding: 20px; text-align: center; margin: 20px 0;">
            <h2 style="color: #3498db; font-size: 32px; letter-spacing: 5px; margin: 0;">${code}</h2>
          </div>
          
          <p style="color: #e74c3c; font-weight: bold;">This code will expire in ${expiryMinutes} ${expiryMinutes === 1 ? 'minute' : 'minutes'}.</p>
          
          <p>If you did not request this password reset, please ignore this email. Your password will remain unchanged.</p>
          
          <hr style="border: none; border-top: 1px solid #ddd; margin: 20px 0;">
          
          <p style="font-size: 12px; color: #7f8c8d; text-align: center;">
            This is an automated message. Please do not reply to this email.
          </p>
        </div>
      </body>
      </html>
    `;

    const text = `
Password Reset Request - ${appName}

Hello,

You have requested to reset your password for your ${appName} account. Please use the following verification code to reset your password:

Verification Code: ${code}

This code will expire in ${expiryMinutes} ${expiryMinutes === 1 ? 'minute' : 'minutes'}.

If you did not request this password reset, please ignore this email. Your password will remain unchanged.

This is an automated message. Please do not reply to this email.
    `;

    return this._sendEmail(email, subject, text, html);
  }

  /**
   * Internal method to send email
   * @param {string} to - Recipient email
   * @param {string} subject - Email subject
   * @param {string} text - Plain text content
   * @param {string} html - HTML content
   * @returns {Promise<boolean>} - Success status
   */
  async _sendEmail(to, subject, text, html) {
    const defaultFrom = process.env.EMAIL_FROM || 'noreply@bookdoon.com';
    const resendFrom = process.env.RESEND_FROM || defaultFrom || 'onboarding@resend.dev';

    // Use Resend (only provider)
    if (this.isConfigured && this.useResend && this.resendClient) {
      try {
        const result = await this.resendClient.emails.send({
          from: resendFrom,
          to: to,
          subject: subject,
          html: html,
          text: text
        });

        // Log full response for debugging
        console.log('📧 Resend API Response:', JSON.stringify(result, null, 2));
        
        // Check if there are any errors in the response
        if (result?.error) {
          logger.error('Resend API returned an error:', {
            error: result.error,
            to,
            from: resendFrom,
            fullResponse: result
          });
          return false;
        }

        // Check if we got a valid email ID
        if (!result?.data?.id) {
          logger.warn('Resend API response missing email ID:', {
            to,
            from: resendFrom,
            fullResponse: result,
            note: 'Email may not have been sent successfully'
          });
          // Still return true if no error was thrown, but log warning
        }

        logger.info('Email sent via Resend:', {
          to,
          subject,
          from: resendFrom,
          id: result?.data?.id,
          status: result?.data?.status || 'unknown'
        });
        return true;
      } catch (error) {
        // Enhanced error logging with specific handling for validation errors
        const errorResponse = error?.response?.data || error?.response || {};
        const errorMessage = errorResponse?.message || error?.message || String(error);
        const errorName = errorResponse?.name || error?.name || 'UnknownError';
        
        console.error('❌ Resend API Error Details:', {
          message: errorMessage,
          name: errorName,
          statusCode: error?.statusCode || error?.response?.status,
          response: errorResponse,
          fullError: error
        });
        
        // Check for domain verification error specifically
        if (errorMessage.includes('domain is not verified') || errorName === 'validation_error') {
          logger.error('❌ DOMAIN NOT VERIFIED - Email sending failed:', {
            message: errorMessage,
            domain: resendFrom.split('@')[1],
            solution: 'Please verify your domain at https://resend.com/domains',
            temporaryFix: 'Use onboarding@resend.dev for testing',
            to,
            from: resendFrom
          });
        } else {
          logger.error('Failed to send email via Resend:', {
            message: errorMessage,
            name: errorName,
            statusCode: error?.statusCode || error?.response?.status,
            response: errorResponse,
            cause: error?.cause,
            to,
            from: resendFrom
          });
        }
        // No fallback
        return false;
      }
    }

    // Not configured: log details for development
    logger.info('=== EMAIL (NOT CONFIGURED - DEVELOPMENT MODE) ===');
    logger.info('From:', defaultFrom);
    logger.info('To:', to);
    logger.info('Subject:', subject);
    logger.info('Text:', text);
    logger.info('HTML:', html);
    logger.info('================================================');
    // Consider success to avoid blocking user flow in development
    return true;
  }

  /**
   * Test email configuration
   * @returns {Promise<boolean>} - Configuration status
   */
  async testConnection() {
    if (!this.isConfigured || !this.resendClient) {
      return false;
    }

    try {
      // Simple no-op call validation for Resend
      return !!this.resendClient;
    } catch (error) {
      logger.error('Email connection test failed:', error);
      return false;
    }
  }
}

// Export singleton instance
module.exports = new EmailService();

