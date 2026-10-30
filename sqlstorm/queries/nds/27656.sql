
WITH AddressCounts AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        SUM(CASE WHEN ca_city LIKE '%city%' THEN 1 ELSE 0 END) AS city_address_count,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length
    FROM customer_address
    GROUP BY ca_state
),
CustomerStats AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS total_customers,
        SUM(cd_dep_count) AS total_dependents,
        SUM(cd_purchase_estimate) AS total_purchase_estimate
    FROM customer_demographics
    JOIN customer ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
    GROUP BY cd_gender
),
SalesAnalysis AS (
    SELECT
        CASE 
            WHEN ws_sales_price < 50 THEN 'Low'
            WHEN ws_sales_price BETWEEN 50 AND 150 THEN 'Medium'
            ELSE 'High'
        END AS price_band,
        COUNT(ws_order_number) AS order_count,
        SUM(ws_ext_sales_price) AS total_sales
    FROM web_sales
    GROUP BY price_band
)
SELECT 
    a.ca_state,
    a.address_count,
    a.city_address_count,
    a.avg_street_name_length,
    c.cd_gender,
    c.total_customers,
    c.total_dependents,
    c.total_purchase_estimate,
    s.price_band,
    s.order_count,
    s.total_sales
FROM AddressCounts a
JOIN CustomerStats c ON a.ca_state = c.cd_gender
JOIN SalesAnalysis s ON c.total_customers > 10
ORDER BY a.address_count DESC, s.total_sales DESC
LIMIT 100;
