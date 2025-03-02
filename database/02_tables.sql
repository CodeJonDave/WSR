BEGIN;

-- Enable UUID extension for generating UUIDs
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Industries table: Stores industry types for companies, allowing dynamic additions
CREATE TABLE IF NOT EXISTS
    industries (
        industry_id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (), -- Unique identifier for each industry
        industry_name VARCHAR(100) UNIQUE NOT NULL, -- Name of the industry (e.g., "Retail"), must be unique
        description TEXT, -- Optional description of the industry
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP -- Timestamp when the industry was added
    );

-- Genres table: Stores song genres dynamically added from Spotify API
CREATE TABLE IF NOT EXISTS
    genres (
        genre_id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (), -- Unique identifier for each genre
        genre_name VARCHAR(50) UNIQUE NOT NULL, -- Name of the genre (e.g., "pop", "rock"), must be unique
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP -- Timestamp when the genre was added
    );

-- Account_manager table: Manages account managers assigned to companies
CREATE TABLE IF NOT EXISTS
    account_manager (
        account_manager_id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (), -- Unique identifier for each account manager
        first_name VARCHAR(50) NOT NULL, -- Manager's first name
        last_name VARCHAR(50) NOT NULL, -- Manager's last name
        email VARCHAR(255) UNIQUE NOT NULL, -- Manager's email, must be unique
        phone VARCHAR(20), -- Manager's phone number, optional
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP -- Timestamp when the manager was added
    );

-- Company table: Represents companies subscribing to the Work Safe Radio service
CREATE TABLE IF NOT EXISTS
    company (
        company_id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (), -- Unique identifier for each company
        company_name VARCHAR(255) UNIQUE NOT NULL, -- Name of the company, must be unique
        company_type company_type NOT NULL, -- Type of company (single_location or multiple_location)
        company_size company_size NOT NULL, -- Size of company (small, medium, large)
        industry_id UUID NOT NULL REFERENCES industries (industry_id) ON DELETE RESTRICT, -- Links to industry type, prevents deletion if used
        contact_email VARCHAR(255) UNIQUE, -- Company contact email, optional but unique if provided
        contact_phone VARCHAR(20), -- Company contact phone, optional
        address TEXT, -- Company address, optional
        subscription_start_date DATE NOT NULL, -- Start date of the company's subscription
        subscription_end_date DATE, -- End date of the subscription, nullable if ongoing
        subscription_status subscription_status NOT NULL, -- Status of subscription (active, inactive, pending)
        payment_interval payment_interval NOT NULL, -- Payment frequency (monthly, quarterly, yearly)
        currency currency NOT NULL, -- Currency for payments (USD, EUR, GBP)
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Timestamp when the company was added
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Timestamp of last update
        account_manager_id UUID NOT NULL REFERENCES account_manager (account_manager_id) ON DELETE SET NULL, -- Assigned account manager, nullable if manager is deleted
        last_payment_date DATE, -- Date of the last payment, optional
        message_interval INT DEFAULT 5 CHECK (message_interval >= 1) -- Frequency of message breaks (e.g., every 5 songs)
    );

-- Company_audit table: Tracks changes to company records for auditing purposes
CREATE TABLE IF NOT EXISTS
    company_audit (
        audit_id BIGSERIAL PRIMARY KEY,
        company_id UUID NOT NULL,
        operation CHAR(1) NOT NULL, -- 'I' = Insert, 'U' = Update, 'D' = Delete
        changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        old_values JSONB,
        new_values JSONB
    );

-- Location table: Represents company locations, each acting as a unique station with operational hours
CREATE TABLE IF NOT EXISTS
    location (
        location_id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (), -- Unique identifier for each location
        company_id UUID NOT NULL REFERENCES company (company_id) ON DELETE CASCADE, -- Links to parent company, cascades on deletion
        location_name VARCHAR(255) NOT NULL, -- Name of the location (e.g., "Warehouse A")
        address TEXT, -- Location address, optional
        contact_email VARCHAR(255) UNIQUE, -- Location contact email, optional but unique if provided
        contact_phone VARCHAR(20), -- Location contact phone, optional
        qr_code VARCHAR(50) UNIQUE NOT NULL, -- QR code for directing users to setup/login page
        station_status station_status DEFAULT 'active', -- Status of the station (active, inactive)
        location_start_time TIME NOT NULL, -- Daily start time for the location’s station (e.g., 09:00)
        location_end_time TIME NOT NULL, -- Daily end time for the location’s station (e.g., 17:00)
        CHECK (location_end_time > location_start_time) -- Ensures end time is after start time, kept for location-level validation
    );

-- Create an audit table for tracking changes on the location table
CREATE TABLE IF NOT EXISTS
    location_audit (
        audit_id BIGSERIAL PRIMARY KEY,
        location_id UUID NOT NULL,
        operation CHAR(1) NOT NULL, -- 'I' = Insert, 'U' = Update, 'D' = Delete
        changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        old_values JSONB,
        new_values JSONB
    );

-- User table: Stores employees pre-registered by the company
CREATE TABLE IF NOT EXISTS
    "user" (
        user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (), -- Unique identifier for each user
        first_name VARCHAR(50) NOT NULL, -- User's first name
        last_name VARCHAR(50) NOT NULL, -- User's last name
        email VARCHAR(255) UNIQUE NOT NULL, -- User's email, must be unique
        phone VARCHAR(20), -- User's phone number, optional
        company_id UUID REFERENCES company (company_id) ON DELETE SET NULL, -- Links to company, nullable if company is deleted
        location_id UUID REFERENCES location (location_id) ON DELETE SET NULL, -- Links to location (station), nullable if location is deleted
        user_role user_role NOT NULL, -- User's role (employee, admin, manager)
        user_status user_status NOT NULL DEFAULT 'pending', -- Registration status (pending, registered, unregistered)
        password_hash TEXT NOT NULL, -- Hash of the default password set during pre-registration
        employee_id VARCHAR(50) UNIQUE NOT NULL, -- Company-issued employee ID, must be unique
        qr_code_used VARCHAR(50) REFERENCES location (qr_code) ON DELETE SET NULL -- Tracks QR code scanned for setup, nullable
    );

-- Create the audit table to track changes for the user table
CREATE TABLE IF NOT EXISTS
    user_audit (
        audit_id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (), -- Unique identifier for the audit record
        action_type VARCHAR(20) NOT NULL, -- Action type (INSERT or UPDATE)
        user_id UUID NOT NULL REFERENCES "user" (user_id), -- The user being updated
        changed_by UUID REFERENCES "user" (user_id), -- User who made the change
        change_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Time of change
        old_data JSONB, -- Old data (before update)
        new_data JSONB -- New data (after update)
    );

-- User_shifts table: Tracks each user’s shift schedule for dynamic playlist updates
CREATE TABLE IF NOT EXISTS
    user_shifts (
        shift_id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (), -- Unique identifier for each shift
        user_id UUID NOT NULL REFERENCES "user" (user_id) ON DELETE CASCADE, -- Links to user, cascades on deletion
        location_id UUID NOT NULL REFERENCES location (location_id) ON DELETE CASCADE, -- Links to location, ensures shift is within station
        shift_start_time TIMESTAMP NOT NULL, -- Start time of the user’s shift, validated by business logic
        shift_end_time TIMESTAMP NOT NULL -- End time of the user’s shift, validated by business logic
        -- Note: No CHECK constraint; shift time validation handled in service business logic
    );

-- User_playlist table: Stores personal song selections for each user
CREATE TABLE IF NOT EXISTS
    user_playlist (
        user_playlist_id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (), -- Unique identifier for each user-song entry
        user_id UUID NOT NULL REFERENCES "user" (user_id) ON DELETE CASCADE, -- Links to user, cascades on deletion
        song_id BIGINT NOT NULL REFERENCES song (song_id) ON DELETE CASCADE, -- Links to song, cascades on deletion
        added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP -- Timestamp when the song was added to user’s playlist
    );

-- Site_playlist table: Aggregates songs for each location’s station playlist with a count
CREATE TABLE IF NOT EXISTS
    site_playlist (
        site_playlist_id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (), -- Unique identifier for each site-song entry
        location_id UUID NOT NULL REFERENCES location (location_id) ON DELETE CASCADE, -- Links to location (station), cascades on deletion
        song_id BIGINT NOT NULL REFERENCES song (song_id) ON DELETE CASCADE, -- Links to song, cascades on deletion
        song_count INT NOT NULL DEFAULT 1 CHECK (song_count >= 0), -- Number of user playlists including this song
        added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP -- Timestamp when the song was first added to site playlist
    );

-- Song table: Stores references to Spotify songs for playback
CREATE TABLE IF NOT EXISTS
    song (
        song_id BIGSERIAL PRIMARY KEY, -- Unique identifier for each song, auto-incrementing 64-bit integer
        title VARCHAR(100) NOT NULL, -- Song title from Spotify API
        metadata JSONB, -- Additional song details from Spotify (e.g., artist, album)
        genre_id UUID REFERENCES genres (genre_id) ON DELETE SET NULL, -- Links to genre, nullable if genre is deleted
        is_clean BOOLEAN NOT NULL DEFAULT FALSE, -- Indicates if the song is HR-compliant
        track_id VARCHAR(50) UNIQUE NOT NULL -- Spotify track ID for API playback (e.g., "6rqhFgbbKwnb9MLmUQDhG8")
    );

-- Flagging table: Tracks flags for songs
CREATE TABLE IF NOT EXISTS
    song_flags (
        flag_id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (), -- Unique identifier for each flag
        song_id BIGINT NOT NULL REFERENCES song (song_id) ON DELETE CASCADE, -- Links to song
        user_id UUID NOT NULL REFERENCES "user" (user_id) ON DELETE SET NULL, -- User who flagged the song
        flagged_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Timestamp when the song was flagged
        flag_status flag_status DEFAULT 'pending', -- Status of the flag (pending, reviewed, dismissed)
        review_comment TEXT, -- Optional comment by the reviewer
        reviewed_by UUID REFERENCES "user" (user_id) ON DELETE SET NULL, -- User who reviewed the flag (optional)
        reviewed_at TIMESTAMP -- Timestamp when the flag was reviewed (optional)
    );

-- Company_messages table: Stores company-wide messages for commercial breaks
CREATE TABLE IF NOT EXISTS
    company_messages (
        message_id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (), -- Unique identifier for each message
        company_id UUID NOT NULL REFERENCES company (company_id) ON DELETE CASCADE, -- Links to company, cascades on deletion
        admin_id UUID REFERENCES "user" (user_id) ON DELETE SET NULL, -- Admin who created the message, nullable if deleted
        audio_file_url TEXT NOT NULL, -- URL or path to the message audio file
        status message_status DEFAULT 'pending', -- Message status (pending, approved, rejected)
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Timestamp when the message was created
        approved_at TIMESTAMP -- Timestamp when the message was approved
    );

-- Location_messages table: Stores location-specific messages for commercial breaks
CREATE TABLE IF NOT EXISTS
    location_messages (
        message_id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (), -- Unique identifier for each message
        location_id UUID NOT NULL REFERENCES location (location_id) ON DELETE CASCADE, -- Links to location, cascades on deletion
        admin_id UUID REFERENCES "user" (user_id) ON DELETE SET NULL, -- Admin who created the message, nullable if deleted
        audio_file_url TEXT NOT NULL, -- URL or path to the message audio file
        status message_status DEFAULT 'pending', -- Message status (pending, approved, rejected)
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Timestamp when the message was created
        approved_at TIMESTAMP -- Timestamp when the message was approved
    );

COMMIT;