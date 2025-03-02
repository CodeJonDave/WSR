BEGIN;

-- Create enum types for consistency and data integrity
-- Enum for company type
CREATE TYPE company_type AS ENUM('single_location', 'multiple_location');

-- Enum for company size
CREATE TYPE company_size AS ENUM('small', 'medium', 'large');

-- Enum for subscription status
CREATE TYPE subscription_status AS ENUM('active', 'inactive', 'pending');

-- Enum for payment interval
CREATE TYPE payment_interval AS ENUM('monthly', 'quarterly', 'yearly');

-- Enum for currency
CREATE TYPE currency AS ENUM('USD', 'EUR', 'GBP');

-- Enum for user_role
CREATE TYPE user_role AS ENUM(
    'employee',
    'company-admin',
    'site-admin',
    'manager'
);

-- Enum for user status
CREATE TYPE user_status AS ENUM('registered', 'unregistered', 'pending');

-- Enum for message status
CREATE TYPE message_status AS ENUM('pending', 'approved', 'rejected');

-- Enum for station status
CREATE TYPE station_status AS ENUM('active', 'inactive');

-- Enum for flag status
CREATE TYPE flag_status AS ENUM('pending', 'non-compliant', 'dismissed');

COMMIT;