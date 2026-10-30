
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_info AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
combined_info AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        si.total_sales,
        si.total_orders,
        si.avg_sales_price
    FROM customer_info ci
    LEFT JOIN sales_info si ON ci.c_customer_sk = si.ws_bill_customer_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    COALESCE(total_sales, 0) AS total_sales,
    COALESCE(total_orders, 0) AS total_orders,
    COALESCE(avg_sales_price, 0) AS avg_sales_price,
    CASE 
        WHEN total_sales IS NULL THEN 'No sales'
        WHEN total_sales < 100 THEN 'Low spender'
        WHEN total_sales BETWEEN 100 AND 500 THEN 'Moderate spender'
        ELSE 'High spender'
    END AS customer_category
FROM combined_info
ORDER BY total_sales DESC
LIMIT 100;
