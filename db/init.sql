-- Init SQL script for Product Catalog database schema

CREATE TABLE IF NOT EXISTS categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    category_id INTEGER REFERENCES categories(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price NUMERIC(10, 2) NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Seed Categories
INSERT INTO categories (name) VALUES 
('Electronics'), 
('Books'), 
('Clothing'), 
('Home & Kitchen'), 
('Sports');

-- PL/pgSQL function to seed bulk data for testing database indexing and pgBadger
CREATE OR REPLACE FUNCTION seed_products_bulk(num_rows INTEGER) 
RETURNS VOID AS $$
DECLARE
    cat_id INTEGER;
    i INTEGER;
BEGIN
    FOR i IN 1..num_rows LOOP
        -- Select a random category id from existing categories
        SELECT id INTO cat_id FROM categories ORDER BY random() LIMIT 1;
        
        INSERT INTO products (category_id, name, description, price, created_at)
        VALUES (
            cat_id,
            'Product ' || i || ' ' || substring(md5(random()::text) from 1 for 8),
            'Description for product number ' || i || '. This is a sample item generated for benchmarking indexes and pgBadger.',
            (random() * 999 + 1)::numeric(10, 2),
            TIMESTAMP '2026-01-01 00:00:00' + random() * (TIMESTAMP '2026-06-01 00:00:00' - TIMESTAMP '2026-01-01 00:00:00')
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Seed initial 10,000 products for performance testing
SELECT seed_products_bulk(10000);
