CREATE TABLE
    company (
        company_id UUID PRIMARY KEY DEFAULT(UUID()),
        name VARCHAR(255) NOT NULL,
        company_type ENUM('single', 'multiple') NOT NULL,
        industry_type INT NOT NULL,
        contact_email VARCHAR(255) UNIQUE,
        contact_phone VARCHAR(20) address TEXT,
        company_admin_id UUID NOT NULL,
        subscription_start_date DATE NOT NULL,
        subscription_end_date DATE,
        payment_interval ENUM('monthly', 'quarterly', 'yearly') NOT NULL,
        is_active BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        account_manager_id UUID NOT NULL,
        last_payment_date DATE,
        FOREIGN KEY (company_admin_id) REFERENCES user(user_id),
        FOREIGN KEY (account_manager_id) REFERENCES account_manager (account_manager_id)
    );

CREATE INDEX company_name_index ON company(name);
CREATE UNIQUE INDEX company_contact_email_index ON company(contact_email);
CREATE INDEX company_company_admin_id_index ON company(company_admin_id);
CREATE INDEX company_account_manager_id_index ON company(account_manager_id);
CREATE INDEX company_subscription_start_dates_index ON company(subscription_start_date, subscription_end_date);

DELIMITER //
CREATE TRIGGER update_company_timestamp
    BEFORE UPDATE ON company
    FOR EACH ROW
    BEGIN
        SET NEW.updated_at = CURRENT_TIMESTAMP;
    END;
//
DELIMITER ;

DELIMITER //
CREATE TRIGGER auto_inactive_company
    BEFORE UPDATE ON company
    FOR EACH ROW
    BEGIN
        IF NEW.subscription_end_date < CURRENT_DATE THEN
            SET NEW.is_active = FALSE;
        END IF;
    END;
//
DELIMITER ;