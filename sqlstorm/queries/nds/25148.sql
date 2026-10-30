WITH address_data AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM customer_address
),
customer_full AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN address_data ad ON c.c_current_addr_sk = ad.ca_address_sk
),
daily_sales AS (
    SELECT 
        d.d_date,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY d.d_date
),
sales_with_customers AS (
    SELECT 
        c.full_name,
        c.cd_gender,
        c.cd_marital_status,
        c.full_address,
        d.total_sales,
        d.total_orders
    FROM customer_full c
    JOIN daily_sales d ON d.d_date = cast('2002-10-01' as date) 
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    full_address,
    total_sales,
    total_orders,
    CASE 
        WHEN total_sales > 1000 THEN 'High Value Customer'
        WHEN total_sales BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_category
FROM sales_with_customers
ORDER BY total_sales DESC;