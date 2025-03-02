BEGIN;

-- Drop existing triggers if they exist
DROP TRIGGER IF EXISTS trigger_update_company_timestamp ON company;

DROP TRIGGER IF EXISTS trigger_auto_update_subscription_status ON company;

DROP TRIGGER IF EXISTS trigger_auto_inactivate_company_with_grace_period ON company;

-- Function to update company.updated_at timestamp
CREATE
OR
REPLACE
    FUNCTION update_company_timestamp () RETURNS TRIGGER AS $$ BEGIN NEW.updated_at = CURRENT_TIMESTAMP;

RETURN NEW;

END;

$$ LANGUAGE plpgsql;

-- Trigger to update updated_at before any update
CREATE TRIGGER trigger_update_company_timestamp BEFORE
UPDATE ON company FOR EACH ROW
EXECUTE FUNCTION update_company_timestamp ();

-- Function to manage subscription_status with payment interval and last_payment_date
CREATE
OR
REPLACE
    FUNCTION auto_update_subscription_status () RETURNS TRIGGER AS $$ BEGIN
    -- Extend subscription_end_date based on last_payment_date if it’s more recent
    IF NEW.last_payment_date IS NOT NULL
    AND NEW.last_payment_date > NEW.subscription_end_date THEN IF NEW.payment_interval = 'monthly' THEN NEW.subscription_end_date = NEW.last_payment_date + INTERVAL '1 month';

ELSIF NEW.payment_interval = 'quarterly' THEN NEW.subscription_end_date = NEW.last_payment_date + INTERVAL '3 months';

ELSIF NEW.payment_interval = 'yearly' THEN NEW.subscription_end_date = NEW.last_payment_date + INTERVAL '1 year';

END IF;

END IF;

-- Update subscription_status based on dates
IF NEW.subscription_end_date < CURRENT_DATE THEN
-- Check grace period (5 days post-interval)
IF NEW.payment_interval = 'monthly'
AND NEW.subscription_end_date + INTERVAL '1 month 5 days' < CURRENT_DATE THEN NEW.subscription_status = 'inactive';

ELSIF NEW.payment_interval = 'quarterly'
AND NEW.subscription_end_date + INTERVAL '3 months 5 days' < CURRENT_DATE THEN NEW.subscription_status = 'inactive';

ELSIF NEW.payment_interval = 'yearly'
AND NEW.subscription_end_date + INTERVAL '1 year 5 days' < CURRENT_DATE THEN NEW.subscription_status = 'inactive';

ELSE NEW.subscription_status = 'pending';

-- Still in grace period
END IF;

ELSIF NEW.subscription_start_date <= CURRENT_DATE
AND NEW.subscription_end_date >= CURRENT_DATE THEN NEW.subscription_status = 'active';

-- Within active period
ELSE NEW.subscription_status = 'pending';

-- Before start or in limbo
END IF;

RETURN NEW;

END;

$$ LANGUAGE plpgsql;

-- Trigger to update subscription_status before updates
CREATE TRIGGER trigger_auto_update_subscription_status BEFORE
UPDATE ON company FOR EACH ROW
EXECUTE FUNCTION auto_update_subscription_status ();

-- Function to log account manager changes for audit
CREATE
OR
REPLACE
    FUNCTION log_account_manager_change () RETURNS TRIGGER AS $$ BEGIN IF NEW.account_manager_id IS DISTINCT
FROM
    OLD.account_manager_id THEN RAISE NOTICE 'Account manager changed for company % from % to %',
    NEW.company_id,
    OLD.account_manager_id,
    NEW.account_manager_id;

END IF;

RETURN NEW;

END;

$$ LANGUAGE plpgsql;

-- Trigger to log account manager changes after updates
CREATE TRIGGER trigger_log_account_manager_change AFTER
UPDATE ON company FOR EACH ROW
EXECUTE FUNCTION log_account_manager_change ();

-- Trigger function to log changes
CREATE
OR
REPLACE
    FUNCTION company_audit_trigger () RETURNS TRIGGER AS $$ BEGIN IF(TG_OP = 'INSERT') THEN
INSERT INTO
    company_audit (company_id, operation, new_values)
VALUES
    (
        NEW.company_id,
        'I',
        CAST(row_to_json (NEW) AS JSONB)
    );

RETURN NEW;

ELSIF (TG_OP = 'UPDATE') THEN
INSERT INTO
    company_audit (company_id, operation, old_values, new_values)
VALUES
    (
        OLD.company_id,
        'U',
        CAST(row_to_json (OLD) AS JSONB),
        CAST(row_to_json (NEW) AS JSONB)
    );

RETURN NEW;

ELSIF (TG_OP = 'DELETE') THEN
INSERT INTO
    company_audit (company_id, operation, old_values)
VALUES
    (
        OLD.company_id,
        'D',
        CAST(row_to_json (OLD) AS JSONB)
    );

RETURN OLD;

END IF;

END;

$$ LANGUAGE plpgsql;

-- Create trigger to log audit records after any DML on company
CREATE TRIGGER trigger_company_audit AFTER
INSERT
    OR
UPDATE
OR DELETE ON company FOR EACH ROW
EXECUTE FUNCTION company_audit_trigger ();

COMMIT;