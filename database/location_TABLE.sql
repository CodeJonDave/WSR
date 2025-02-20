DROP TABLE IF EXISTS "location";

CREATE TABLE "location" (
    location_id BINARY(16) PRIMARY KEY,
    company_id BINARY(16) NOT NULL,
    name VARCHAR(255) NOT NULL UNIQUE,
    address VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL,
    country VARCHAR(100) NOT NULL,
    postal_code VARCHAR(10) NOT NULL,
    timezone VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(255) NOT NULL,
    location_type INT NOT NULL,
    num_employees INT NOT NULL DEFAULT 1,
    number_of_shifts INT NOT NULL DEFAULT 1,
    work_start_time TIME NOT NULL,
    work_end_time TIME NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (location_type) REFERENCES "location_type" (location_type_id),
    FOREIGN KEY (company_id) REFERENCES "company" (company_id),
);

CREATE INDEX location_name_index ON location (name);