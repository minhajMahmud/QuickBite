const { Resend } = require('resend');
const env = require('../config/env');

const resend = new Resend(env.resend.apiKey);

/**
 * Send email verification link
 */
async function sendVerificationEmail(email, name, verificationToken, verificationUrl) {
  try {
    const confirmLink = `${verificationUrl}?token=${verificationToken}`;
    
    const result = await resend.emails.send({
      from: `${env.resend.fromName} <${env.resend.fromEmail}>`,
      to: email,
      subject: 'Verify your QuickBite account',
      html: `
        <!DOCTYPE html>
        <html>
          <head>
            <meta charset="utf-8">
            <style>
              body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
              .container { max-width: 600px; margin: 0 auto; padding: 20px; }
              .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; border-radius: 8px 8px 0 0; text-align: center; }
              .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 8px 8px; }
              .button { background: #667eea; color: white; padding: 12px 30px; border-radius: 5px; text-decoration: none; display: inline-block; margin: 20px 0; }
              .footer { text-align: center; margin-top: 20px; font-size: 12px; color: #666; }
              .expiry { color: #e74c3c; font-size: 14px; margin-top: 20px; }
            </style>
          </head>
          <body>
            <div class="container">
              <div class="header">
                <h1>Welcome to QuickBite! 🍽️</h1>
              </div>
              <div class="content">
                <p>Hi ${name},</p>
                <p>Thank you for signing up for QuickBite! Please verify your email address to activate your account.</p>
                <p style="text-align: center;">
                  <a href="${confirmLink}" class="button">Verify Email Address</a>
                </p>
                <p>Or copy this link in your browser:</p>
                <p style="word-break: break-all; background: #e8e8e8; padding: 10px; border-radius: 5px;">
                  ${confirmLink}
                </p>
                <p class="expiry">⏰ This link expires in 24 hours</p>
                <p>If you didn't create this account, please ignore this email.</p>
              </div>
              <div class="footer">
                <p>QuickBite © 2026 | All rights reserved</p>
              </div>
            </div>
          </body>
        </html>
      `,
    });

    return { success: true, messageId: result.id };
  } catch (error) {
    console.error('Error sending verification email:', error);
    throw new Error(`Failed to send verification email: ${error.message}`);
  }
}

/**
 * Send password reset email
 */
async function sendPasswordResetEmail(email, name, resetToken, resetUrl) {
  try {
    const resetLink = `${resetUrl}?email=${encodeURIComponent(email)}&token=${resetToken}`;
    
    const result = await resend.emails.send({
      from: `${env.resend.fromName} <${env.resend.fromEmail}>`,
      to: email,
      subject: 'Reset your QuickBite password',
      html: `
        <!DOCTYPE html>
        <html>
          <head>
            <meta charset="utf-8">
            <style>
              body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
              .container { max-width: 600px; margin: 0 auto; padding: 20px; }
              .header { background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); color: white; padding: 30px; border-radius: 8px 8px 0 0; text-align: center; }
              .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 8px 8px; }
              .button { background: #f5576c; color: white; padding: 12px 30px; border-radius: 5px; text-decoration: none; display: inline-block; margin: 20px 0; }
              .footer { text-align: center; margin-top: 20px; font-size: 12px; color: #666; }
              .warning { background: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; border-radius: 5px; margin: 20px 0; }
              .expiry { color: #e74c3c; font-size: 14px; margin-top: 20px; }
            </style>
          </head>
          <body>
            <div class="container">
              <div class="header">
                <h1>Password Reset Request 🔐</h1>
              </div>
              <div class="content">
                <p>Hi ${name},</p>
                <p>We received a request to reset your password. Click the button below to create a new password.</p>
                <p style="text-align: center;">
                  <a href="${resetLink}" class="button">Reset Password</a>
                </p>
                <p>Or copy this link in your browser:</p>
                <p style="word-break: break-all; background: #e8e8e8; padding: 10px; border-radius: 5px;">
                  ${resetLink}
                </p>
                <div class="warning">
                  <strong>⚠️ Security Notice:</strong> If you didn't request this, please ignore this email or contact us.
                </div>
                <p class="expiry">⏰ This link expires in 1 hour</p>
              </div>
              <div class="footer">
                <p>QuickBite © 2026 | All rights reserved</p>
              </div>
            </div>
          </body>
        </html>
      `,
    });

    return { success: true, messageId: result.id };
  } catch (error) {
    console.error('Error sending password reset email:', error);
    throw new Error(`Failed to send password reset email: ${error.message}`);
  }
}

/**
 * Send first-time login welcome email
 */
async function sendFirstLoginEmail(email, name) {
  try {
    const result = await resend.emails.send({
      from: `${env.resend.fromName} <${env.resend.fromEmail}>`,
      to: email,
      subject: 'Welcome to QuickBite! Your first login 🎉',
      html: `
        <!DOCTYPE html>
        <html>
          <head>
            <meta charset="utf-8">
            <style>
              body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
              .container { max-width: 600px; margin: 0 auto; padding: 20px; }
              .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; border-radius: 8px 8px 0 0; text-align: center; }
              .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 8px 8px; }
              .feature-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 15px; margin: 20px 0; }
              .feature { background: white; padding: 15px; border-radius: 5px; border-left: 4px solid #667eea; }
              .feature-title { font-weight: bold; color: #667eea; }
              .button { background: #667eea; color: white; padding: 12px 30px; border-radius: 5px; text-decoration: none; display: inline-block; margin: 20px 0; }
              .footer { text-align: center; margin-top: 20px; font-size: 12px; color: #666; }
            </style>
          </head>
          <body>
            <div class="container">
              <div class="header">
                <h1>Welcome to QuickBite! 🎉</h1>
              </div>
              <div class="content">
                <p>Hi ${name},</p>
                <p>Your account is now active and ready to use! Enjoy amazing food delivered to your doorstep.</p>
                
                <div class="feature-grid">
                  <div class="feature">
                    <div class="feature-title">🍕 Browse Restaurants</div>
                    <p>Discover local restaurants and cuisines</p>
                  </div>
                  <div class="feature">
                    <div class="feature-title">⚡ Quick Delivery</div>
                    <p>Fast and reliable delivery service</p>
                  </div>
                  <div class="feature">
                    <div class="feature-title">💰 Save with Coupons</div>
                    <p>Exclusive deals and discounts</p>
                  </div>
                  <div class="feature">
                    <div class="feature-title">⭐ Track Orders</div>
                    <p>Real-time delivery tracking</p>
                  </div>
                </div>
                
                <p style="text-align: center;">
                  <a href="${env.frontend.url}" class="button">Start Ordering Now</a>
                </p>
                
                <p><strong>Need help?</strong> Check out our <a href="${env.frontend.url}/help">Help Center</a> or contact our support team.</p>
              </div>
              <div class="footer">
                <p>QuickBite © 2026 | All rights reserved</p>
              </div>
            </div>
          </body>
        </html>
      `,
    });

    return { success: true, messageId: result.id };
  } catch (error) {
    console.error('Error sending first login email:', error);
    throw new Error(`Failed to send first login email: ${error.message}`);
  }
}

/**
 * Send account confirmation email (new account)
 */
async function sendAccountConfirmationEmail(email, name) {
  try {
    const result = await resend.emails.send({
      from: `${env.resend.fromName} <${env.resend.fromEmail}>`,
      to: email,
      subject: 'Your QuickBite account has been created ✅',
      html: `
        <!DOCTYPE html>
        <html>
          <head>
            <meta charset="utf-8">
            <style>
              body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
              .container { max-width: 600px; margin: 0 auto; padding: 20px; }
              .header { background: linear-gradient(135deg, #11998e 0%, #38ef7d 100%); color: white; padding: 30px; border-radius: 8px 8px 0 0; text-align: center; }
              .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 8px 8px; }
              .info-box { background: #e8f5e9; border-left: 4px solid #4caf50; padding: 15px; border-radius: 5px; margin: 20px 0; }
              .footer { text-align: center; margin-top: 20px; font-size: 12px; color: #666; }
            </style>
          </head>
          <body>
            <div class="container">
              <div class="header">
                <h1>Account Created Successfully ✅</h1>
              </div>
              <div class="content">
                <p>Hi ${name},</p>
                <p>Your QuickBite account has been successfully created!</p>
                
                <div class="info-box">
                  <strong>What's next?</strong>
                  <ul>
                    <li>Complete your profile information</li>
                    <li>Add delivery addresses</li>
                    <li>Start exploring restaurants near you</li>
                    <li>Place your first order and enjoy a special welcome discount!</li>
                  </ul>
                </div>
                
                <p>Your account email: <strong>${email}</strong></p>
                <p>If you have any questions, feel free to reach out to our support team.</p>
              </div>
              <div class="footer">
                <p>QuickBite © 2026 | All rights reserved</p>
              </div>
            </div>
          </body>
        </html>
      `,
    });

    return { success: true, messageId: result.id };
  } catch (error) {
    console.error('Error sending account confirmation email:', error);
    throw new Error(`Failed to send account confirmation email: ${error.message}`);
  }
}

module.exports = {
  sendVerificationEmail,
  sendPasswordResetEmail,
  sendFirstLoginEmail,
  sendAccountConfirmationEmail,
};
