
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city AS city,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count
    FROM customer AS c
    JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesInfo AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales AS ws
    GROUP BY ws.ws_bill_customer_sk
),
CombinedInfo AS (
    SELECT
        ci.full_name,
        ci.city,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.cd_purchase_estimate,
        ci.cd_credit_rating,
        si.total_sales,
        si.order_count,
        si.total_profit
    FROM CustomerInfo ci
    LEFT JOIN SalesInfo si ON ci.c_customer_sk = si.ws_bill_customer_sk
)
SELECT 
    full_name,
    city,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    cd_purchase_estimate,
    cd_credit_rating,
    COALESCE(total_sales, 0) AS total_sales,
    COALESCE(order_count, 0) AS order_count,
    COALESCE(total_profit, 0) AS total_profit,
    CASE 
        WHEN total_sales >= 1000 THEN 'High Value'
        WHEN total_sales >= 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM CombinedInfo
WHERE city ILIKE '%York%' AND cd_gender = 'M'
ORDER BY total_sales DESC;
