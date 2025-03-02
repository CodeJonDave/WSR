BEGIN;

-- Drop existing triggers if they exist
DROP TRIGGER IF EXISTS trigger_update_company_timestamp ON company;

DROP TRIGGER IF EXISTS trigger_auto_update_subscription_status ON company;

DROP TRIGGER IF EXISTS trigger_log_account_manager_change ON company;

DROP TRIGGER IF EXISTS trigger_company_audit ON company;

DROP TRIGGER IF EXISTS trigger_prevent_company_name_change ON company;

DROP TRIGGER IF EXISTS trigger_reactivate_subscription_status ON company;

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

-- Function to manage subscription_status based on payments
CREATE
OR
REPLACE
    FUNCTION auto_update_subscription_status () RETURNS TRIGGER AS $$ BEGIN
    -- Extend subscription_end_date based on last_payment_date if it's newer
    IF NEW.last_payment_date IS NOT NULL
    AND NEW.last_payment_date > OLD.subscription_end_date THEN IF NEW.payment_interval = 'monthly' THEN NEW.subscription_end_date = NEW.last_payment_date + INTERVAL '1 month';

ELSIF NEW.payment_interval = 'quarterly' THEN NEW.subscription_end_date = NEW.last_payment_date + INTERVAL '3 months';

ELSIF NEW.payment_interval = 'yearly' THEN NEW.subscription_end_date = NEW.last_payment_date + INTERVAL '1 year';

END IF;

END IF;

-- Determine subscription status
IF NEW.subscription_end_date >= CURRENT_DATE THEN NEW.subscription_status = 'active';

-- Fully paid up
ELSIF NEW.subscription_end_date < CURRENT_DATE THEN
-- Grace period (5 days after interval)
IF NEW.payment_interval = 'monthly'
AND NEW.subscription_end_date + INTERVAL '1 month 5 days' >= CURRENT_DATE THEN NEW.subscription_status = 'pending';

ELSIF NEW.payment_interval = 'quarterly'
AND NEW.subscription_end_date + INTERVAL '3 months 5 days' >= CURRENT_DATE THEN NEW.subscription_status = 'pending';

ELSIF NEW.payment_interval = 'yearly'
AND NEW.subscription_end_date + INTERVAL '1 year 5 days' >= CURRENT_DATE THEN NEW.subscription_status = 'pending';

ELSE NEW.subscription_status = 'inactive';

-- Past due & past grace period
END IF;

END IF;

RETURN NEW;

END;

$$ LANGUAGE plpgsql;

-- Trigger to auto-update subscription_status before updates
CREATE TRIGGER trigger_auto_update_subscription_status BEFORE
UPDATE ON company FOR EACH ROW
EXECUTE FUNCTION auto_update_subscription_status ();

-- Function to log account manager changes for auditing
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

-- Trigger to log account manager changes
CREATE TRIGGER trigger_log_account_manager_change AFTER
UPDATE ON company FOR EACH ROW
EXECUTE FUNCTION log_account_manager_change ();

-- Function to log changes for auditing purposes
CREATE
OR
REPLACE
    FUNCTION company_audit_trigger () RETURNS TRIGGER AS $$ BEGIN IF TG_OP = 'INSERT' THEN
INSERT INTO
    company_audit (company_id, operation, new_values)
VALUES
    (
        NEW.company_id,
        'I',
        CAST(row_to_json (NEW) AS JSONB)
    );

RETURN NEW;

ELSIF TG_OP = 'UPDATE' THEN
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

ELSIF TG_OP = 'DELETE' THEN
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

-- Trigger to log audit records after any DML on company
CREATE TRIGGER trigger_company_audit AFTER
INSERT
    OR
UPDATE
OR DELETE ON company FOR EACH ROW
EXECUTE FUNCTION company_audit_trigger ();

-- Function to prevent company_name changes
CREATE
OR
REPLACE
    FUNCTION prevent_company_name_change () RETURNS TRIGGER AS $$ BEGIN IF TG_OP = 'UPDATE'
    AND OLD.company_name IS DISTINCT
FROM
    NEW.company_name THEN RAISE EXCEPTION 'Changing the company_name is not allowed';

END IF;

RETURN NEW;

END;

$$ LANGUAGE plpgsql;

-- Trigger to prevent company_name updates
CREATE TRIGGER trigger_prevent_company_name_change BEFORE
UPDATE ON company FOR EACH ROW
EXECUTE FUNCTION prevent_company_name_change ();

-- Function to reactivate subscription when a payment is made
CREATE
OR
REPLACE
    FUNCTION reactivate_subscription_status () RETURNS TRIGGER AS $$ BEGIN
    -- Ensure last_payment_date is updated and after the current subscription_end_date
    IF NEW.last_payment_date IS NOT NULL
    AND NEW.last_payment_date > OLD.subscription_end_date THEN
    -- Extend subscription_end_date based on payment interval
    IF NEW.payment_interval = 'monthly' THEN NEW.subscription_end_date = NEW.last_payment_date + INTERVAL '1 month';

ELSIF NEW.payment_interval = 'quarterly' THEN NEW.subscription_end_date = NEW.last_payment_date + INTERVAL '3 months';

ELSIF NEW.payment_interval = 'yearly' THEN NEW.subscription_end_date = NEW.last_payment_date + INTERVAL '1 year';

END IF;

-- Reactivate subscription if valid
IF NEW.subscription_end_date >= CURRENT_DATE THEN NEW.subscription_status = 'active';

ELSE NEW.subscription_status = 'pending';

-- Payment made but still within grace period
END IF;

END IF;

RETURN NEW;

END;

$$ LANGUAGE plpgsql;

-- Trigger to update subscription_status upon payment update
CREATE TRIGGER trigger_reactivate_subscription_status BEFORE
UPDATE ON company FOR EACH ROW WHEN (
    OLD.last_payment_date IS DISTINCT
    FROM
        NEW.last_payment_date
)
EXECUTE FUNCTION reactivate_subscription_status ();

COMMIT;