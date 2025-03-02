BEGIN;

--------------------------------------------------
-- Audit Table and Trigger for the Location Table
--------------------------------------------------
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

-- Drop the audit trigger if it already exists
DROP TRIGGER IF EXISTS trigger_location_audit ON location;

-- Create a trigger function to log INSERT, UPDATE, DELETE operations on location
CREATE
OR
REPLACE
    FUNCTION location_audit_trigger () RETURNS TRIGGER AS $$ BEGIN IF(TG_OP = 'INSERT') THEN
INSERT INTO
    location_audit (location_id, operation, new_values)
VALUES
    (
        NEW.location_id,
        'I',
        CAST(row_to_json (NEW) AS JSONB)
    );

RETURN NEW;

ELSIF (TG_OP = 'UPDATE') THEN
INSERT INTO
    location_audit (location_id, operation, old_values, new_values)
VALUES
    (
        OLD.location_id,
        'U',
        CAST(row_to_json (OLD) AS JSONB),
        CAST(row_to_json (NEW) AS JSONB)
    );

RETURN NEW;

ELSIF (TG_OP = 'DELETE') THEN
INSERT INTO
    location_audit (location_id, operation, old_values)
VALUES
    (
        OLD.location_id,
        'D',
        CAST(row_to_json (OLD) AS JSONB)
    );

RETURN OLD;

END IF;

END;

$$ LANGUAGE plpgsql;

-- Create the audit logging trigger for the location table
CREATE TRIGGER trigger_location_audit AFTER
INSERT
    OR
UPDATE
OR DELETE ON location FOR EACH ROW
EXECUTE FUNCTION location_audit_trigger ();

--------------------------------------------------
-- Immutable Field Trigger for the QR Code
--------------------------------------------------
-- Drop the QR code immutability trigger if it already exists
DROP TRIGGER IF EXISTS trigger_prevent_qr_code_change ON location;

-- Create a trigger function to prevent changes to the qr_code column after creation
CREATE
OR
REPLACE
    FUNCTION prevent_qr_code_change () RETURNS TRIGGER AS $$ BEGIN IF TG_OP = 'UPDATE'
    AND OLD.qr_code IS DISTINCT
FROM
    NEW.qr_code THEN RAISE EXCEPTION 'QR code cannot be modified once set';

END IF;

RETURN NEW;

END;

$$ LANGUAGE plpgsql;

-- Create the trigger to enforce immutability of the qr_code field
CREATE TRIGGER trigger_prevent_qr_code_change BEFORE
UPDATE ON location FOR EACH ROW
EXECUTE FUNCTION prevent_qr_code_change ();

--------------------------------------------------
-- Timestamp Update Trigger (Optional)
--------------------------------------------------
-- Optionally, add an updated_at column if it doesn't already exist.
ALTER TABLE location
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

-- Drop the updated_at trigger if it exists
DROP TRIGGER IF EXISTS trigger_update_location_timestamp ON location;

-- Create a trigger function to update the updated_at timestamp on every update
CREATE
OR
REPLACE
    FUNCTION update_location_timestamp () RETURNS TRIGGER AS $$ BEGIN NEW.updated_at = CURRENT_TIMESTAMP;

RETURN NEW;

END;

$$ LANGUAGE plpgsql;

-- Create the trigger to update updated_at before any update on the location table
CREATE TRIGGER trigger_update_location_timestamp BEFORE
UPDATE ON location FOR EACH ROW
EXECUTE FUNCTION update_location_timestamp ();

COMMIT;