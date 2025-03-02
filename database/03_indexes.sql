BEGIN;

-- Index on account_manager.last_name for faster lookup by last name.
CREATE INDEX idx_account_manager_last_name ON account_manager (last_name);

-- Index on account_manager.first_name for faster lookup by first name.
CREATE INDEX idx_account_manager_first_name ON account_manager (first_name);

-- Index on company.industry_id (foreign key) for faster joins with the industries table.
CREATE INDEX idx_company_industry_id ON company (industry_id);

-- Index on company.account_manager_id (foreign key) for faster joins with the account_manager table.
CREATE INDEX idx_company_account_manager_id ON company (account_manager_id);

-- Index on company.subscription_status to improve filtering by subscription status.
CREATE INDEX idx_company_subscription_status ON company (subscription_status);

-- Index on company.subscription_start_date to speed up queries filtering or sorting by the start date.
CREATE INDEX idx_company_subscription_start_date ON company (subscription_start_date);

-- Index on location.company_id (foreign key) for faster joins with the company table.
CREATE INDEX idx_location_company_id ON location (company_id);

-- Index on location.station_status to quickly filter locations by their operational status.
CREATE INDEX idx_location_station_status ON location (station_status);

-- Index on "user".company_id (foreign key) to improve queries involving company lookups.
CREATE INDEX idx_user_company_id ON "user" (company_id);

-- Index on "user".location_id (foreign key) to improve queries involving location lookups.
CREATE INDEX idx_user_location_id ON "user" (location_id);

-- Index on "user".approved_by to optimize queries filtering by the approver of a user.
CREATE INDEX idx_user_approved_by ON "user" (approved_by);

-- Index on "user".user_role for faster filtering based on user roles.
CREATE INDEX idx_user_role ON "user" (user_role);

-- Index on "user".user_status to quickly filter users by their registration status.
CREATE INDEX idx_user_status ON "user" (user_status);

-- Index on user_shifts.user_id (foreign key) to speed up lookups of shifts by user.
CREATE INDEX idx_user_shifts_user_id ON user_shifts (user_id);

-- Index on user_shifts.location_id (foreign key) to speed up lookups of shifts by location.
CREATE INDEX idx_user_shifts_location_id ON user_shifts (location_id);

-- Index on user_shifts.shift_start_time to facilitate queries ordered or filtered by shift start time.
CREATE INDEX idx_user_shifts_start_time ON user_shifts (shift_start_time);

-- Index on user_playlist.user_id to improve queries retrieving a user's playlist.
CREATE INDEX idx_user_playlist_user_id ON user_playlist (user_id);

-- Index on user_playlist.song_id to speed up lookups of song entries in user playlists.
CREATE INDEX idx_user_playlist_song_id ON user_playlist (song_id);

-- Composite index on user_playlist for efficient queries filtering by both user_id and song_id.
CREATE INDEX idx_user_playlist_user_song ON user_playlist (user_id, song_id);

-- Index on site_playlist.location_id to speed up queries on the station playlist by location.
CREATE INDEX idx_site_playlist_location_id ON site_playlist (location_id);

-- Index on site_playlist.song_id for faster lookup of songs in site playlists.
CREATE INDEX idx_site_playlist_song_id ON site_playlist (song_id);

-- Composite index on site_playlist for efficient queries filtering by both location_id and song_id.
CREATE INDEX idx_site_playlist_location_song ON site_playlist (location_id, song_id);

-- Index on song.genre_id (foreign key) to speed up joins with the genres table.
CREATE INDEX idx_song_genre_id ON song (genre_id);

-- Index on song.title to improve text search performance on song titles.
CREATE INDEX idx_song_title ON song (title);

-- GIN index on song.metadata to optimize JSONB queries on the metadata column.
CREATE INDEX idx_song_metadata ON song USING gin (metadata);

-- Index on company_messages.company_id (foreign key) for faster joins with the company table.
CREATE INDEX idx_company_messages_company_id ON company_messages (company_id);

-- Index on company_messages.admin_id to speed up queries filtering by the message creator.
CREATE INDEX idx_company_messages_admin_id ON company_messages (admin_id);

-- Index on company_messages.status to improve filtering by message status.
CREATE INDEX idx_company_messages_status ON company_messages (status);

-- Index on location_messages.location_id (foreign key) for faster joins with the location table.
CREATE INDEX idx_location_messages_location_id ON location_messages (location_id);

-- Index on location_messages.admin_id to speed up queries filtering by the message creator.
CREATE INDEX idx_location_messages_admin_id ON location_messages (admin_id);

-- Index on location_messages.status to improve filtering by message status.
CREATE INDEX idx_location_messages_status ON location_messages (status);

COMMIT;