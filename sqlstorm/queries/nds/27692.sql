
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
date_info AS (
    SELECT 
        d.d_date,
        d.d_day_name,
        d.d_month_seq,
        d.d_year
    FROM date_dim d
    WHERE d.d_year BETWEEN 1998 AND 2001
),
sales_info AS (
    SELECT
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
benchmark AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.ca_zip,
        di.d_year,
        di.d_month_seq,
        si.total_sales,
        si.total_orders
    FROM customer_info ci
    JOIN date_info di ON di.d_year BETWEEN EXTRACT(YEAR FROM DATE '2002-10-01') - 3 AND EXTRACT(YEAR FROM DATE '2002-10-01')
    LEFT JOIN sales_info si ON ci.c_customer_sk = si.ws_bill_customer_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    ca_zip,
    d_year,
    d_month_seq,
    COALESCE(total_sales, 0) AS total_sales,
    COALESCE(total_orders, 0) AS total_orders,
    CASE 
        WHEN total_sales > 1000 THEN 'High Value'
        WHEN total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value
FROM benchmark
ORDER BY total_sales DESC
LIMIT 100;
