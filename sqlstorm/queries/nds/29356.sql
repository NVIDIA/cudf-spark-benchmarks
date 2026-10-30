
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
SaleStats AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_sales_price) AS total_sales
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
Summary AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.cd_gender,
        ci.cd_marital_status,
        ss.total_orders,
        ss.total_sales
    FROM CustomerInfo ci
    LEFT JOIN SaleStats ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    ss.full_name,
    ss.ca_city,
    ss.ca_state,
    ss.cd_gender,
    ss.cd_marital_status,
    COALESCE(ss.total_orders, 0) AS total_orders,
    COALESCE(ss.total_sales, 0.00) AS total_sales,
    CASE 
        WHEN ss.total_sales > 1000 THEN 'High Value'
        WHEN ss.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM Summary ss
ORDER BY ss.total_sales DESC
LIMIT 100;
