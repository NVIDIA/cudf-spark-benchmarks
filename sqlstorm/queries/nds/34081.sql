
WITH  sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ad.ca_city,
        ad.ca_state
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ad ON c.c_current_addr_sk = ad.ca_address_sk
),
top_customers AS (
    SELECT
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.ca_city,
        ci.ca_state,
        ss.total_sales,
        ss.total_orders
    FROM customer_info ci
    JOIN sales_summary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
    WHERE ss.sales_rank <= 10
)
SELECT 
    tc.c_first_name || ' ' || tc.c_last_name AS customer_name,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.ca_city,
    tc.ca_state,
    COALESCE(tc.total_sales, 0) AS total_sales,
    COALESCE(tc.total_orders, 0) AS total_orders,
    (SELECT COUNT(DISTINCT ws_order_number) 
     FROM web_sales 
     WHERE ws_bill_customer_sk = tc.c_customer_sk) AS distinct_orders,
    (CASE 
        WHEN tc.total_sales > 1000 THEN 'High Value'
        WHEN tc.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END) AS customer_value 
FROM top_customers tc
ORDER BY total_sales DESC;
