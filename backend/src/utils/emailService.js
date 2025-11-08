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
    const smtpHost = process.env.SMTP_HOST;
    const smtpPort = process.env.SMTP_PORT;
    const smtpUser = process.env.SMTP_USER;
    const smtpPassword = process.env.SMTP_PASSWORD;
    const smtpFrom = process.env.SMTP_FROM || smtpUser || 'noreply@teekoob.com';

    if (smtpHost && smtpPort && smtpUser && smtpPassword) {
      try {
        const nodemailer = require('nodemailer');
        
        this.transporter = nodemailer.createTransport({
          host: smtpHost,
          port: parseInt(smtpPort, 10),
          secure: smtpPort === '465', // true for 465, false for other ports
          auth: {
            user: smtpUser,
            pass: smtpPassword,
          },
        });

        this.isConfigured = true;
        logger.info('Email service configured with SMTP');
      } catch (error) {
        logger.error('Failed to initialize email transporter:', error);
        this.isConfigured = false;
      }
    } else {
      logger.warn('Email service not configured. Emails will be logged to console only.');
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
    const subject = 'Password Reset Code - Teekoob';
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
          
          <p>You have requested to reset your password for your Teekoob account. Please use the following verification code to reset your password:</p>
          
          <div style="background-color: #ffffff; border: 2px dashed #3498db; border-radius: 5px; padding: 20px; text-align: center; margin: 20px 0;">
            <h2 style="color: #3498db; font-size: 32px; letter-spacing: 5px; margin: 0;">${code}</h2>
          </div>
          
          <p style="color: #e74c3c; font-weight: bold;">This code will expire in 15 minutes.</p>
          
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
Password Reset Request - Teekoob

Hello,

You have requested to reset your password for your Teekoob account. Please use the following verification code to reset your password:

Verification Code: ${code}

This code will expire in 15 minutes.

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
    const smtpFrom = process.env.SMTP_FROM || process.env.SMTP_USER || 'noreply@teekoob.com';

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
          messageId: info.messageId,
        });

        return true;
      } catch (error) {
        logger.error('Failed to send email:', error);
        return false;
      }
    } else {
      // Development mode: Log email to console
      logger.info('=== EMAIL (NOT CONFIGURED - DEVELOPMENT MODE) ===');
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

