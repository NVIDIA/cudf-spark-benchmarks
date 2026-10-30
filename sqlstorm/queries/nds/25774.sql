
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),

SalesInfo AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),

MergedInfo AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.cd_gender,
        si.total_sales,
        si.order_count
    FROM CustomerInfo ci
    LEFT JOIN SalesInfo si ON ci.c_customer_sk = si.ws_bill_customer_sk
)

SELECT 
    full_name,
    ca_city AS city,
    ca_state AS state,
    cd_gender AS gender,
    COALESCE(total_sales, 0) AS total_sales,
    COALESCE(order_count, 0) AS number_of_orders
FROM MergedInfo
WHERE (ca_city LIKE '%York%' OR ca_state = 'NY')
ORDER BY total_sales DESC
LIMIT 100;
