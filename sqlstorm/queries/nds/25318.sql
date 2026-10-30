
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesInfo AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
CombinedInfo AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.ca_country,
        ci.cd_gender,
        ci.cd_marital_status,
        si.total_sales,
        si.order_count
    FROM CustomerInfo ci
    LEFT JOIN SalesInfo si ON ci.c_customer_sk = si.ws_bill_customer_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    ca_country,
    cd_gender,
    cd_marital_status,
    total_sales,
    order_count,
    RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM CombinedInfo
WHERE total_sales IS NOT NULL
ORDER BY sales_rank
LIMIT 100;
