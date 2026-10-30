
WITH CustomerInfo AS (
    SELECT 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_email_address,
        d.d_date AS purchase_date,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023 AND cd.cd_purchase_estimate > 5000
),
AggregatedInfo AS (
    SELECT 
        ca_state,
        COUNT(*) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(DISTINCT CASE WHEN cd_gender = 'M' THEN full_name END) AS male_customers,
        COUNT(DISTINCT CASE WHEN cd_gender = 'F' THEN full_name END) AS female_customers
    FROM CustomerInfo
    GROUP BY ca_state
)
SELECT 
    ca_state,
    customer_count,
    avg_purchase_estimate,
    male_customers,
    female_customers,
    ROUND((male_customers * 1.0 / NULLIF(customer_count, 0)) * 100, 2) AS male_percentage,
    ROUND((female_customers * 1.0 / NULLIF(customer_count, 0)) * 100, 2) AS female_percentage
FROM AggregatedInfo
ORDER BY ca_state;
