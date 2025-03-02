BEGIN;

-- Index on industries.industry_name
-- Purpose: Speeds up lookups and joins by industry name, as it’s unique and likely queried
CREATE UNIQUE INDEX IF NOT EXISTS idx_industries_industry_name ON industries (industry_name);

-- Index on genres.genre_name
-- Purpose: Speeds up lookups and joins by genre name when adding songs from Spotify API
CREATE UNIQUE INDEX IF NOT EXISTS idx_genres_genre_name ON genres (genre_name);

-- Index on account_manager.email
-- Purpose: Speeds up lookups by email, which is unique and likely used for authentication or searches
CREATE UNIQUE INDEX IF NOT EXISTS idx_account_manager_email ON account_manager (email);

-- Index on company.company_name
-- Purpose: Speeds up lookups by company name, which is unique and may be searched
CREATE UNIQUE INDEX IF NOT EXISTS idx_company_company_name ON company (company_name);

-- Index on company.industry_id
-- Purpose: Speeds up joins with industries table for company categorization
CREATE INDEX IF NOT EXISTS idx_company_industry_id ON company (industry_id);

-- Index on company.account_manager_id
-- Purpose: Speeds up joins with account_manager for assigned managers
CREATE INDEX IF NOT EXISTS idx_company_account_manager_id ON company (account_manager_id);

-- Index on location.qr_code
-- Purpose: Speeds up lookups by QR code when users scan for setup
CREATE UNIQUE INDEX IF NOT EXISTS idx_location_qr_code ON location (qr_code);

-- Index on location.company_id
-- Purpose: Speeds up joins and lookups for all locations under a company
CREATE INDEX IF NOT EXISTS idx_location_company_id ON location (company_id);

-- Index on user.email
-- Purpose: Speeds up lookups by email, which is unique and used for login or searches
CREATE UNIQUE INDEX IF NOT EXISTS idx_user_email ON user(email);

-- Index on user.employee_id
-- Purpose: Speeds up lookups by employee ID, which is unique and tied to pre-registration
CREATE UNIQUE INDEX IF NOT EXISTS idx_user_employee_id ON user(employee_id);

-- Index on user.company_id
-- Purpose: Speeds up joins and lookups for users under a company
CREATE INDEX IF NOT EXISTS idx_user_company_id ON user(company_id);

-- Index on user.location_id
-- Purpose: Speeds up joins and lookups for users at a specific location
CREATE INDEX IF NOT EXISTS idx_user_location_id ON user(location_id);

-- Index on user_shifts.user_id
-- Purpose: Speeds up lookups and joins for a user’s shift schedule
CREATE INDEX IF NOT EXISTS idx_user_shifts_user_id ON user_shifts (user_id);

-- Index on user_shifts.location_id
-- Purpose: Speeds up lookups and joins for shifts at a specific location
CREATE INDEX IF NOT EXISTS idx_user_shifts_location_id ON user_shifts (location_id);

-- Index on user_shifts.shift_start_time
-- Purpose: Speeds up queries checking active shifts (e.g., WHERE shift_start_time <= NOW())
CREATE INDEX IF NOT EXISTS idx_user_shifts_shift_start_time ON user_shifts (shift_start_time);

-- Index on user_shifts.shift_end_time
-- Purpose: Speeds up queries checking shift endings (e.g., WHERE shift_end_time >= NOW())
CREATE INDEX IF NOT EXISTS idx_user_shifts_shift_end_time ON user_shifts (shift_end_time);

-- Index on user_playlist.user_id
-- Purpose: Speeds up lookups and joins for a user’s personal playlist
CREATE INDEX IF NOT EXISTS idx_user_playlist_user_id ON user_playlist (user_id);

-- Index on user_playlist.song_id
-- Purpose: Speeds up joins with song table for playlist contents
CREATE INDEX IF NOT EXISTS idx_user_playlist_song_id ON user_playlist (song_id);

-- Index on site_playlist.location_id
-- Purpose: Speeds up lookups and joins for a location’s active playlist
CREATE INDEX IF NOT EXISTS idx_site_playlist_location_id ON site_playlist (location_id);

-- Index on site_playlist.song_id
-- Purpose: Speeds up joins with song table and updates to song_count
CREATE INDEX IF NOT EXISTS idx_site_playlist_song_id ON site_playlist (song_id);

-- Index on song.track_id
-- Purpose: Speeds up lookups by Spotify track ID for playback and searches
CREATE UNIQUE INDEX IF NOT EXISTS idx_song_track_id ON song (track_id);

-- Index on song.genre_id
-- Purpose: Speeds up joins with genres table for song categorization
CREATE INDEX IF NOT EXISTS idx_song_genre_id ON song (genre_id);

-- Index on company_messages.company_id
-- Purpose: Speeds up lookups and joins for company-wide messages
CREATE INDEX IF NOT EXISTS idx_company_messages_company_id ON company_messages (company_id);

-- Index on location_messages.location_id
-- Purpose: Speeds up lookups and joins for location-specific messages
CREATE INDEX IF NOT EXISTS idx_location_messages_location_id ON location_messages (location_id);

-- Index on song_id for quick lookups of flagged songs
CREATE INDEX IF NOT EXISTS idx_song_flags_song_id ON song_flags (song_id);

-- Index on user_id for quick lookups of flags by a specific user
CREATE INDEX IF NOT EXISTS idx_song_flags_user_id ON song_flags (user_id);

-- Index on status for quick filtering of flagged songs by their review status
CREATE INDEX IF NOT EXISTS idx_song_flags_status ON song_flags (status);

-- Index on flagged_at for efficient retrieval of recent flags
CREATE INDEX IF NOT EXISTS idx_song_flags_flagged_at ON song_flags (flagged_at);

COMMIT;