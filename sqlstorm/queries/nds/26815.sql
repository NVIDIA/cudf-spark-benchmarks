
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        LOWER(ca_city) AS lower_city,
        SUBSTRING(ca_zip, 1, 5) AS zip_prefix
    FROM customer_address
),
enhanced_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        a.full_address,
        a.lower_city,
        a.zip_prefix
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN processed_addresses a ON c.c_current_addr_sk = a.ca_address_sk
),
sales_summary AS (
    SELECT
        dc.d_year,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT c.c_customer_sk) AS unique_customers
    FROM web_sales ws
    JOIN date_dim dc ON ws.ws_sold_date_sk = dc.d_date_sk
    JOIN enhanced_customers c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE dc.d_year = 2023
    GROUP BY dc.d_year
)
SELECT 
    ess.d_year,
    ess.total_quantity,
    ess.total_sales,
    ess.unique_customers,
    ROUND(ess.total_sales / NULLIF(ess.total_quantity, 0), 2) AS avg_sales_price_per_item
FROM sales_summary ess
ORDER BY ess.total_sales DESC;
