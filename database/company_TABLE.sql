DROP TABLE IF EXISTS "company";

CREATE TABLE "company" (
    company_id BINARY(16) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    industry VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone VARCHAR(20) NOT NULL UNIQUE,
    address VARCHAR(255) NOT NULL UNIQUE,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL,
    country VARCHAR(100) NOT NULL,
    postal_code VARCHAR(10) NOT NULL,
    timezone VARCHAR(100) NOT NULL,
    website VARCHAR(255),
    default_language VARCHAR(100) NOT NULL,
    default_currency VARCHAR(100) NOT NULL,
    subscription_scale VARCHAR(10) NOT NULL CHECK (subscription_scale IN ('SINGLE', 'MULTI')),
    subscription_status VARCHAR(10) NOT NULL CHECK (subscription_status IN ('ACTIVE', 'INACTIVE')),
    max_locations INT NOT NULL DEFAULT 1,
    max_employees INT NOT NULL DEFAULT 1,
    message_quota INT NOT NULL DEFAULT 50,
    requires_2fa BOOLEAN NOT NULL DEFAULT FALSE,
    content_filtering BOOLEAN NOT NULL DEFAULT FALSE,
    data_retention INT NOT NULL DEFAULT 30,
    logo_url VARCHAR(255),
    theme_color VARCHAR(7),
    welcome_message TEXT,
    owner_id BINARY(16) NOT NULL,
    FOREIGN KEY (owner_id) REFERENCES owners (owner_id),
    account_manager_email VARCHAR(255),
    INDEX (email),
    INDEX (phone),
    INDEX (address)
);

-- Creating the trigger for converting UUID to binary
DELIMITER //

CREATE TRIGGER before_insert_company
BEFORE INSERT ON company
FOR EACH ROW
BEGIN
    -- Convert the UUID to binary and set the company_id field
    SET NEW.company_id = UUID_TO_BIN(UUID());
END;
//

CREATE TRIGGER update_company_timestamp
BEFORE UPDATE ON company
FOR EACH ROW
BEGIN
    SET NEW.updated_at = CURRENT_TIMESTAMP;
END;
//

CREATE TRIGGER log_company_changes
AFTER UPDATE ON company
FOR EACH ROW
BEGIN
    INSERT INTO company_audit_log (company_id, old_value, new_value, changed_at)
    VALUES (OLD.company_id, CONCAT('name: ', OLD.name, ', email: ', OLD.email), CONCAT('name: ', NEW.name, ', email: ', NEW.email), CURRENT_TIMESTAMP);
END;
//

CREATE TRIGGER archive_company_before_delete
BEFORE DELETE ON company
FOR EACH ROW
BEGIN
    INSERT INTO company_archive SELECT * FROM company WHERE company_id = OLD.company_id;
END;
//

BEFORE INSERT ON employees
FOR EACH ROW
BEGIN
    DECLARE company_exists INT;
    SELECT COUNT(*) INTO company_exists FROM company WHERE company_id = NEW.company_id;
    
    IF company_exists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The company ID does not exist';
    END IF;
END;
//

DELIMITER ;