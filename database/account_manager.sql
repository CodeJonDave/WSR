CREATE account_manager (
    account_manager_id UUID PRIMARY KEY DEFAULT(UUID()),
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE INDEX idx_account_manager_name ON account_manager (last_name, first_name);
CREATE UNIQUE INDEX idx_account_manager_email ON account_manager (email);
CREATE INDEX idx_account_manager_phone ON account_manager (phone);

DELIMITER //
CREATE TRIGGER update_account_manager_timestamp
    BEFORE UPDATE ON account_manager
    FOR EACH ROW
    BEGIN
        SET NEW.updated_at = CURRENT_TIMESTAMP;
    END;
//
DELIMITER ;
