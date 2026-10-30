
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        UPPER(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
    WHERE 
        ca_country = 'USA'
),
customer_purchases AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
address_sales AS (
    SELECT 
        pa.ca_address_sk,
        cp.c_customer_sk,
        cp.total_sales,
        cp.order_count
    FROM 
        processed_addresses pa
    JOIN 
        customer_purchases cp ON pa.ca_address_sk = cp.c_customer_sk
)
SELECT 
    a.ca_address_sk,
    a.full_address,
    a.ca_city,
    a.ca_state,
    a.ca_zip,
    COALESCE(c.total_sales, 0) AS total_sales,
    COALESCE(c.order_count, 0) AS order_count
FROM 
    processed_addresses a
LEFT JOIN 
    customer_purchases c ON a.ca_address_sk = c.c_customer_sk
ORDER BY 
    total_sales DESC
LIMIT 100;
