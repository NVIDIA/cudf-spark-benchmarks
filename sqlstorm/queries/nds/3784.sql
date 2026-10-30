
WITH ranked_sales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
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
        cd.cd_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
high_value_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_purchase_estimate,
        rs.total_sales
    FROM customer_info ci
    JOIN ranked_sales rs ON ci.c_customer_sk = rs.ws_bill_customer_sk
    WHERE rs.sales_rank <= 10
),
address_info AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT ci.c_customer_sk) AS customer_count
    FROM customer_address ca
    LEFT JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN customer_info ci ON ci.c_customer_sk = c.c_customer_sk
    GROUP BY ca.ca_address_sk, ca.ca_city, ca.ca_state
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.cd_gender,
    hvc.cd_marital_status,
    hvc.total_sales,
    ai.ca_city,
    ai.ca_state,
    ai.customer_count,
    CASE 
        WHEN hvc.cd_purchase_estimate IS NULL THEN 'No Estimate'
        WHEN hvc.cd_purchase_estimate > 5000 THEN 'High Value'
        ELSE 'Standard Value'
    END AS customer_value_category
FROM high_value_customers hvc
JOIN address_info ai ON hvc.c_customer_sk = ai.customer_count
ORDER BY hvc.total_sales DESC;
