
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male' 
            WHEN cd.cd_gender = 'F' THEN 'Female' 
            ELSE 'Other' 
        END AS gender,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesDetails AS (
    SELECT 
        ws.ws_bill_customer_sk AS customer_sk,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 1 AND 365
    GROUP BY ws.ws_bill_customer_sk
),
CustomerBenchmark AS (
    SELECT 
        ci.full_name,
        ci.gender,
        ci.ca_city,
        ci.ca_state,
        ci.ca_country,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.order_count, 0) AS order_count
    FROM CustomerInfo ci
    LEFT JOIN SalesDetails sd ON ci.c_customer_sk = sd.customer_sk
)
SELECT 
    full_name,
    gender,
    ca_city,
    ca_state,
    ca_country,
    total_sales,
    order_count,
    CASE 
        WHEN total_sales = 0 THEN 'No Purchases'
        WHEN total_sales > 0 AND total_sales <= 500 THEN 'Low Spender'
        WHEN total_sales > 500 AND total_sales <= 2000 THEN 'Medium Spender'
        ELSE 'High Spender'
    END AS spending_category
FROM CustomerBenchmark
ORDER BY total_sales DESC
LIMIT 100;
