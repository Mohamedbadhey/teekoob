const logger = require('./logger');

/**
 * Email Service for sending emails
 * Supports SMTP configuration via environment variables
 * Falls back to console logging in development if not configured
 */

class EmailService {
  constructor() {
    this.transporter = null;
    this.isConfigured = false;
    this._initializeTransporter();
  }

  _initializeTransporter() {
    // Check if email is configured
    // Support both SMTP_PASS and SMTP_PASSWORD for backward compatibility
    const smtpHost = process.env.SMTP_HOST;
    const smtpPort = process.env.SMTP_PORT;
    const smtpUser = process.env.SMTP_USER;
    const smtpPassword = (process.env.SMTP_PASS || process.env.SMTP_PASSWORD)?.trim(); // Trim whitespace
    // Support both EMAIL_FROM and SMTP_FROM for backward compatibility
    const smtpFrom = process.env.EMAIL_FROM || process.env.SMTP_FROM || smtpUser || 'noreply@bookdoon.com';
    // Support SMTP_SECURE environment variable (true/false string)
    const smtpSecure = process.env.SMTP_SECURE === 'true' || smtpPort === '465';

    // Debug logging to help identify missing configuration
    console.log('📧 Email Service Configuration Check:');
    console.log('  - SMTP_HOST:', smtpHost ? '✅ SET' : '❌ MISSING');
    console.log('  - SMTP_PORT:', smtpPort ? `✅ SET (${smtpPort})` : '❌ MISSING');
    console.log('  - SMTP_USER:', smtpUser ? '✅ SET' : '❌ MISSING');
    console.log('  - SMTP_PASS:', smtpPassword ? '✅ SET (***hidden***)' : '❌ MISSING');
    console.log('  - SMTP_SECURE:', smtpSecure);
    console.log('  - EMAIL_FROM:', smtpFrom);

    if (smtpHost && smtpPort && smtpUser && smtpPassword) {
      try {
        const nodemailer = require('nodemailer');
        
        // For Gmail, prefer port 587 with STARTTLS over 465 with SSL
        // Port 587 is more reliable from cloud platforms like Railway
        const port = parseInt(smtpPort, 10);
        const useSecure = smtpSecure && port === 465;
        const useStartTLS = !useSecure && (port === 587 || port === 25);
        
        this.transporter = nodemailer.createTransport({
          host: smtpHost,
          port: port,
          secure: useSecure, // true for 465, false for other ports
          requireTLS: useStartTLS, // Use STARTTLS for port 587
          auth: {
            user: smtpUser,
            pass: smtpPassword,
          },
          // Connection timeout settings (in milliseconds)
          connectionTimeout: 10000, // 10 seconds
          greetingTimeout: 10000, // 10 seconds
          socketTimeout: 10000, // 10 seconds
          // Retry settings
          pool: true,
          maxConnections: 1,
          maxMessages: 3,
          // Debug mode (set to true for troubleshooting)
          debug: process.env.SMTP_DEBUG === 'true',
          logger: process.env.SMTP_DEBUG === 'true',
        });

        this.isConfigured = true;
        logger.info('✅ Email service configured with SMTP', {
          host: smtpHost,
          port: smtpPort,
          secure: useSecure,
          requireTLS: useStartTLS,
          from: smtpFrom
        });
        console.log('✅ Email service successfully initialized!');
        console.log(`   Using ${useSecure ? 'SSL' : useStartTLS ? 'STARTTLS' : 'plain'} connection on port ${port}`);
      } catch (error) {
        logger.error('❌ Failed to initialize email transporter:', error);
        console.error('❌ Email transporter initialization error:', error.message);
        this.isConfigured = false;
      }
    } else {
      const missing = [];
      if (!smtpHost) missing.push('SMTP_HOST');
      if (!smtpPort) missing.push('SMTP_PORT');
      if (!smtpUser) missing.push('SMTP_USER');
      if (!smtpPassword) missing.push('SMTP_PASS or SMTP_PASSWORD');
      
      logger.warn('⚠️ Email service not configured. Missing:', missing);
      logger.warn('⚠️ Emails will be logged to console only.');
      console.warn('⚠️ Email service not configured. Missing variables:', missing.join(', '));
      console.warn('⚠️ Emails will be logged to console only in development mode.');
      this.isConfigured = false;
    }
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
    // Support both EMAIL_FROM and SMTP_FROM for backward compatibility
    const smtpFrom = process.env.EMAIL_FROM || process.env.SMTP_FROM || process.env.SMTP_USER || 'noreply@bookdoon.com';

    if (this.isConfigured && this.transporter) {
      try {
        const info = await this.transporter.sendMail({
          from: smtpFrom,
          to: to,
          subject: subject,
          text: text,
          html: html,
        });

        logger.info('Email sent successfully:', {
          to,
          subject,
          from: smtpFrom,
          messageId: info.messageId,
        });

        return true;
      } catch (error) {
        logger.error('Failed to send email:', {
          message: error.message,
          code: error.code,
          command: error.command,
          response: error.response,
          responseCode: error.responseCode
        });
        
        // Log more details for connection errors
        if (error.code === 'ETIMEDOUT' || error.code === 'ECONNREFUSED') {
          logger.error('SMTP Connection Error Details:', {
            host: process.env.SMTP_HOST,
            port: process.env.SMTP_PORT,
            suggestion: 'Try using port 587 with STARTTLS instead of 465 with SSL, or check if your hosting provider allows SMTP connections'
          });
        }
        
        return false;
      }
    } else {
      // Development mode: Log email to console
      logger.info('=== EMAIL (NOT CONFIGURED - DEVELOPMENT MODE) ===');
      logger.info('From:', smtpFrom);
      logger.info('To:', to);
      logger.info('Subject:', subject);
      logger.info('Text:', text);
      logger.info('HTML:', html);
      logger.info('================================================');
      
      // In development, we'll consider it successful even though we just logged it
      return true;
    }
  }

  /**
   * Test email configuration
   * @returns {Promise<boolean>} - Configuration status
   */
  async testConnection() {
    if (!this.isConfigured || !this.transporter) {
      return false;
    }

    try {
      await this.transporter.verify();
      return true;
    } catch (error) {
      logger.error('Email connection test failed:', error);
      return false;
    }
  }
}

// Export singleton instance
module.exports = new EmailService();

