BEGIN;

-- Function to get account manager details
CREATE
OR
REPLACE
    FUNCTION get_account_manager_details (company_id UUID, user_role user_role) RETURNS
TABLE (
    account_manager_name TEXT,
    account_manager_email TEXT,
    account_manager_phone TEXT
) AS $$ BEGIN
-- Only allow managers and company admins to retrieve account manager details
IF user_role = 'manager'
OR user_role = 'company_admin' THEN
RETURN QUERY
SELECT
    CONCAT(am.first_name, ' ', am.last_name) AS account_manager_name,
    am.email AS account_manager_email,
    am.phone AS account_manager_phone
FROM
    company c
    JOIN account_manager am ON c.account_manager_id = am.account_manager_id
WHERE
    c.company_id = company_id;

-- Fixing this line to refer to the input variable directly
ELSE
RETURN QUERY
SELECT
    'Unauthorized access',
    NULL,
    NULL;

END IF;

END;

$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get company details for an authorized user
CREATE
OR
REPLACE
    FUNCTION get_company_details_admin_user (user_role user_role) RETURNS
TABLE (
    company_name TEXT,
    company_email TEXT,
    company_phone TEXT,
    company_address TEXT,
    company_city TEXT,
    company_state TEXT,
    company_zip TEXT,
    company_country TEXT,
    account_manager_name TEXT,
    account_manager_email TEXT,
    account_manager_phone TEXT
) AS $$ BEGIN
-- Only allow managers and company admins to retrieve company details
IF user_role = 'manager'
OR user_role = 'company_admin'
OR user_role = 'location_admin' THEN
RETURN QUERY
SELECT
    c.company_name,
    c.contact_email,
    c.contact_phone,
    c.address,
    c.city,
    c.state,
    c.zip,
    c.country,
    CONCAT(am.first_name, ' ', am.last_name) AS account_manager_name,
    am.email AS account_manager_email,
    am.phone AS account_manager_phone
FROM
    company c
    LEFT JOIN account_manager am ON c.account_manager_id = am.account_manager_id;

ELSE
RETURN QUERY
SELECT
    'Unauthorized access',
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL;

END IF;

END;

$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMIT;