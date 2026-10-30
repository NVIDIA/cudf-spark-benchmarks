WITH  address_hierarchy AS (
    SELECT ca_address_sk, ca_street_name, ca_city, ca_state, 
           ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY ca_city) AS city_rank
    FROM customer_address
    WHERE ca_country = 'USA'
),
demographic_summary AS (
    SELECT cd_gender, cd_marital_status, AVG(cd_purchase_estimate) AS avg_purchase, 
           COUNT(DISTINCT cd_demo_sk) AS demo_count
    FROM customer_demographics
    WHERE cd_credit_rating IS NOT NULL
    GROUP BY cd_gender, cd_marital_status
),
sales_summary AS (
    SELECT 
        SUM(ws_net_paid) AS total_net_paid,
        SUM(ws_quantity) AS total_quantity,
        ws_ship_mode_sk,
        CASE 
            WHEN SUM(ws_net_paid) > 1000 THEN 'High Value'
            ELSE 'Low Value'
        END AS sales_category
    FROM web_sales
    WHERE ws_sold_date_sk >= (
        SELECT MAX(d_date_sk) 
        FROM date_dim 
        WHERE d_year = 2001
    )
    GROUP BY ws_ship_mode_sk
)

SELECT a.ca_city, a.ca_state, 
       d.cd_gender, d.cd_marital_status, 
       COALESCE(s.total_net_paid, 0) AS total_net_paid,
       COALESCE(s.sales_category, 'Unknown') AS sales_category
FROM address_hierarchy a
FULL OUTER JOIN demographic_summary d ON a.city_rank = 1 
LEFT JOIN sales_summary s ON a.ca_address_sk = s.ws_ship_mode_sk
WHERE (d.avg_purchase > 500 OR d.demo_count > 10) 
  AND (a.ca_city IS NOT NULL OR a.ca_state IS NOT NULL)
  AND s.total_quantity IS NOT NULL;