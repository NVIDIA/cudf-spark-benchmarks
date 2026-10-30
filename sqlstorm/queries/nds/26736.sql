
WITH AddressDetails AS (
    SELECT 
        ca_address_id,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city AS city,
        UPPER(ca_state) AS state,
        CONCAT(ca_zip, ', ', ca_country) AS zip_country
    FROM 
        customer_address
),
CustomerStats AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.d_year,
        SUM(COALESCE(ws.ws_sales_price, 0)) AS total_spent
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, d.d_year
),
CustomerInfo AS (
    SELECT 
        cs.full_name,
        cs.total_spent,
        ad.full_address,
        ad.city,
        ad.state,
        ad.zip_country
    FROM 
        CustomerStats cs
    JOIN AddressDetails ad ON cs.c_customer_id = ad.ca_address_id
    WHERE 
        cs.total_spent > 1000
)
SELECT 
    full_name,
    total_spent,
    full_address,
    city,
    state,
    zip_country
FROM 
    CustomerInfo
ORDER BY 
    total_spent DESC
LIMIT 50;
