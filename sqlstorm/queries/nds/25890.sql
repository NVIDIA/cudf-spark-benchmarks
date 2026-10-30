
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_sk) AS unique_addresses,
        MAX(LENGTH(ca_street_name)) AS max_street_length,
        MIN(LENGTH(ca_street_name)) AS min_street_length,
        AVG(LENGTH(ca_street_name)) AS avg_street_length
    FROM customer_address
    GROUP BY ca_state
),
CustomerStats AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS num_customers,
        AVG(cd_dep_count) AS avg_dependents,
        MAX(cd_purchase_estimate) AS max_purchase_estimate,
        MIN(cd_purchase_estimate) AS min_purchase_estimate
    FROM customer_demographics
    JOIN customer ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
    GROUP BY cd_gender
),
SalesStats AS (
    SELECT 
        t.d_year,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_sales_price) AS avg_sales_price
    FROM web_sales
    JOIN date_dim t ON t.d_date_sk = ws_sold_date_sk
    GROUP BY t.d_year
)
SELECT 
    a.ca_state,
    a.unique_addresses,
    a.max_street_length,
    a.min_street_length,
    a.avg_street_length,
    c.cd_gender,
    c.num_customers,
    c.avg_dependents,
    c.max_purchase_estimate,
    c.min_purchase_estimate,
    s.d_year,
    s.total_sales,
    s.total_orders,
    s.avg_sales_price
FROM AddressStats a
CROSS JOIN CustomerStats c
CROSS JOIN SalesStats s
WHERE a.unique_addresses > 1000 AND c.num_customers > 50 AND s.total_sales > 1000000
ORDER BY a.ca_state, c.cd_gender, s.d_year;
