BEGIN;

-- Create enum types for consistency and data integrity


CREATE TYPE company_type AS ENUM('single_location', 'multiple_location');

CREATE TYPE company_size AS ENUM('small', 'medium', 'large');

CREATE TYPE subscription_status AS ENUM('active', 'inactive', 'pending');

CREATE TYPE payment_interval AS ENUM('monthly', 'quarterly', 'yearly');

CREATE TYPE currency AS ENUM('USD', 'EUR', 'GBP');

CREATE TYPE user_role AS ENUM('employee', 'company-admin', 'site-admin' 'manager');

CREATE TYPE user_status AS ENUM('registered', 'unregistered', 'pending');

CREATE TYPE message_status AS ENUM('pending', 'approved', 'rejected');

CREATE TYPE station_status AS ENUM('active', 'inactive');

COMMIT;