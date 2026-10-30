
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS full_address,
        UPPER(ca_city) AS city_upper,
        LOWER(ca_state) AS state_lower,
        CONCAT(TRIM(ca_zip), '-', SUBSTRING(ca_zip, 1, 5)) AS formatted_zip
    FROM 
        customer_address
),
customer_sales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        MAX(ws.ws_sold_date_sk) AS last_order_date
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.total_sales,
    cs.order_count,
    pa.full_address,
    pa.city_upper,
    pa.state_lower,
    pa.formatted_zip
FROM 
    customer_sales cs
JOIN 
    customer_address ca ON cs.c_customer_sk = ca.ca_address_sk 
JOIN 
    processed_addresses pa ON ca.ca_address_sk = pa.ca_address_sk
WHERE 
    cs.total_sales > 1000
ORDER BY 
    cs.total_sales DESC;
