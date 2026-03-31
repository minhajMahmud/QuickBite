-- Migration: Add profile fields to users table
-- Created: 2026-03-31

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS date_of_birth DATE;

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS gender VARCHAR(30);
