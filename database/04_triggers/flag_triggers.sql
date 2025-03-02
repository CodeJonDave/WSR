BEGIN;

CREATE
OR
REPLACE
    FUNCTION remove_song_from_playlists_on_flag_change () RETURNS TRIGGER AS $$ BEGIN
    -- Check if the flag's status is being updated to 'non-compliant'
    IF NEW.status = 'non-compliant'
    AND OLD.status != 'non-compliant' THEN
    -- Remove the song from site_playlist
DELETE FROM site_playlist
WHERE
    song_id = NEW.song_id;

-- Remove the song from user_playlist
DELETE FROM user_playlist
WHERE
    song_id = NEW.song_id;

END IF;

RETURN NEW;

END;

$$ LANGUAGE plpgsql;

CREATE TRIGGER flag_status_change_trigger AFTER
UPDATE ON song_flags FOR EACH ROW
EXECUTE FUNCTION remove_song_from_playlists_on_flag_change ();

CREATE
OR
REPLACE
    FUNCTION prevent_flagged_songs_from_adding () RETURNS TRIGGER AS $$ BEGIN
    -- Check if the song is already 'dismissed'
    IF EXISTS (
        SELECT
            1
        FROM
            song_flags
        WHERE
            song_id = NEW.song_id
            AND status = 'dismissed'
    ) THEN
    -- Prevent re-flagging the song
    RAISE EXCEPTION 'Song is dismissed and cannot be flagged again';

END IF;

-- Check if the song is in 'pending' or 'non-compliant' status
IF EXISTS (
    SELECT
        1
    FROM
        song_flags
    WHERE
        song_id = NEW.song_id
        AND status IN ('pending', 'non-compliant')
) THEN
-- Prevent insertion by raising an exception
RAISE EXCEPTION 'Cannot add song with status "pending" or "non-compliant" to playlist';

END IF;

RETURN NEW;

END;

$$ LANGUAGE plpgsql;

CREATE TRIGGER prevent_flagged_song_in_site_playlist BEFORE
INSERT
    ON site_playlist FOR EACH ROW
EXECUTE FUNCTION prevent_flagged_songs_from_adding ();

CREATE TRIGGER prevent_flagged_song_in_user_playlist BEFORE
INSERT
    ON user_playlist FOR EACH ROW
EXECUTE FUNCTION prevent_flagged_songs_from_adding ();


-- Function to update song flag.updated_at timestamp
CREATE
OR
REPLACE
    FUNCTION update_song_flag_stamp () RETURNS TRIGGER AS $$ BEGIN NEW.updated_at = CURRENT_TIMESTAMP;

RETURN NEW;

END;

$$ LANGUAGE plpgsql;

-- Trigger to update updated_at before any update
CREATE TRIGGER trigger_update_company_timestamp BEFORE
UPDATE ON company FOR EACH ROW
EXECUTE FUNCTION update_company_timestamp ();
COMMIT;