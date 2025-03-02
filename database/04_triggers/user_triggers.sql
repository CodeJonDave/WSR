Begin;

-- Trigger function to set default user values and validate roles
CREATE
OR
REPLACE
    FUNCTION set_default_user_values () RETURNS TRIGGER AS $$ BEGIN
    -- Set default user_status to 'pending' if not provided
    IF NEW.user_status IS NULL THEN NEW.user_status := 'pending';

END IF;

-- Ensure the user_role is valid
IF NEW.user_role NOT IN('employee', 'admin', 'manager') THEN RAISE EXCEPTION 'Invalid user role: %',
NEW.user_role;

END IF;

-- Set default qr_code_used to NULL if not provided
IF NEW.qr_code_used IS NULL THEN NEW.qr_code_used := NULL;

END IF;

RETURN NEW;

END;

$$ LANGUAGE plpgsql;

-- Trigger that sets default values and validates user role before insert
CREATE TRIGGER trigger_set_default_user_values BEFORE
INSERT
    ON "user" FOR EACH ROW
EXECUTE FUNCTION set_default_user_values ();

-- Trigger function to log changes to the user table
CREATE
OR
REPLACE
    FUNCTION log_user_changes () RETURNS TRIGGER AS $$ BEGIN
    -- If the action is an UPDATE, log the changes
    IF TG_OP = 'UPDATE' THEN
INSERT INTO
    user_audit (
        action_type,
        user_id,
        changed_by,
        old_data,
        new_data
    )
VALUES
    (
        'UPDATE',
        NEW.user_id,
        CURRENT_USER,
        TO_JSONB (OLD),
        TO_JSONB (NEW)
    );

ELSIF TG_OP = 'INSERT' THEN
-- Log when a new user is inserted
INSERT INTO
    user_audit (action_type, user_id, changed_by, new_data)
VALUES
    (
        'INSERT',
        NEW.user_id,
        CURRENT_USER,
        TO_JSONB (NEW)
    );

END IF;

RETURN NEW;

END;

$$ LANGUAGE plpgsql;

-- Trigger that logs every insert or update into the user table
CREATE TRIGGER trigger_log_user_changes AFTER
INSERT
    OR
UPDATE ON "user" FOR EACH ROW
EXECUTE FUNCTION log_user_changes ();

-- Trigger function to ensure company_id exists when provided
CREATE
OR
REPLACE
    FUNCTION check_company_exists () RETURNS TRIGGER AS $$ BEGIN
    -- If company_id is provided, ensure it exists in the company table
    IF NEW.company_id IS NOT NULL
    AND NOT EXISTS (
        SELECT
            1
        FROM
            company
        WHERE
            company_id = NEW.company_id
    ) THEN RAISE EXCEPTION 'Company with ID % does not exist',
    NEW.company_id;

END IF;

RETURN NEW;

END;

$$ LANGUAGE plpgsql;

-- Trigger to ensure company_id exists before inserting or updating
CREATE TRIGGER trigger_check_company_exists BEFORE
INSERT
    OR
UPDATE ON "user" FOR EACH ROW
EXECUTE FUNCTION check_company_exists ();

-- Trigger function to ensure location_id exists when provided
CREATE
OR
REPLACE
    FUNCTION check_location_exists () RETURNS TRIGGER AS $$ BEGIN
    -- If location_id is provided, ensure it exists in the location table
    IF NEW.location_id IS NOT NULL
    AND NOT EXISTS (
        SELECT
            1
        FROM
            location
        WHERE
            location_id = NEW.location_id
    ) THEN RAISE EXCEPTION 'Location with ID % does not exist',
    NEW.location_id;

END IF;

RETURN NEW;

END;

$$ LANGUAGE plpgsql;

-- Trigger to ensure location_id exists before inserting or updating
CREATE TRIGGER trigger_check_location_exists BEFORE
INSERT
    OR
UPDATE ON "user" FOR EACH ROW
EXECUTE FUNCTION check_location_exists ();