-- Migration: Add 6-digit email verification code
-- Created: April 6, 2026

-- Add email verification code column to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS email_verification_code VARCHAR(6);
ALTER TABLE users ADD COLUMN IF NOT EXISTS email_verification_code_expires_at TIMESTAMP;
