-- Tables creation

-- Regions Table
CREATE TABLE oltp.regions (
    id SERIAL PRIMARY KEY,
    region_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- Reps Table
CREATE TABLE oltp.reps (
    id VARCHAR(20) PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
	last_name VARCHAR(50) NOT NULL,
	gender VARCHAR(10) NOT NULL,
	grade VARCHAR(50),
    email VARCHAR(150) UNIQUE,
    phone_number VARCHAR(20),
    region_id INT REFERENCES oltp.regions(id),
    date_joined DATE,
	date_left DATE,
	exit_reason VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- Customers Table
CREATE TABLE oltp.customers (
    id VARCHAR(20) PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
	last_name VARCHAR(50) NOT NULL,
    email VARCHAR(150) UNIQUE,
    phone_number VARCHAR(20),
	gender VARCHAR(50),
    address TEXT,
    region_id INT REFERENCES oltp.regions(id),
    rep_id VARCHAR(20) REFERENCES oltp.reps(id),
    signup_date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);



-- Deals Table
CREATE TABLE oltp.deals (
    deal_id SERIAL PRIMARY KEY,
    deal_name VARCHAR(20) NOT NULL,
    product_type VARCHAR(20),
    base_price DECIMAL(12,2) NOT NULL,
    duration_months INT,
	monthly_payment DECIMAL(12,2) NOT NULL,
    warranty_period_months INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);



-- Contracts Table
CREATE TABLE oltp.contracts (
    id VARCHAR(20) PRIMARY KEY,
    customer_id VARCHAR(20) REFERENCES oltp.customers(id),
    rep_id VARCHAR(20) REFERENCES oltp.reps(id),
    deal_id INT REFERENCES oltp.deals(deal_id),
    contract_start DATE DEFAULT CURRENT_DATE,
    contract_end DATE,
    contract_status VARCHAR(50) DEFAULT 'active',
	system_id VARCHAR(20) NOT NUL
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- Payments Table
CREATE TABLE IF NOT EXISTS oltp.payments
(
    id VARCHAR(50) PRIMARY KEY,
    contract_id VARCHAR(20) REFERENCES oltp.contracts(id),
    deal_id INT REFERENCES oltp.deals(deal_id),
    amount DECIMAL(12,2) NOT NULL,
    payment_date DATE,
    payment_method VARCHAR(50),
    payment_status VARCHAR(50),
    rep_id VARCHAR(20) REFERENCES oltp.reps(id),
    last_payment_date date,
    next_payment_date date,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
)