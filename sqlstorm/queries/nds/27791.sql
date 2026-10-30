WITH address_stats AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        SUM(CASE WHEN ca_city LIKE 'San%' THEN 1 ELSE 0 END) AS san_city_count
    FROM customer_address
    GROUP BY ca_state
),
customer_stats AS (
    SELECT 
        cd_gender,
        COUNT(c_customer_sk) AS customer_count,
        AVG(cd_dep_count) AS avg_dependents,
        SUM(cd_purchase_estimate) AS total_purchase_estimate
    FROM customer_demographics
    INNER JOIN customer ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
    GROUP BY cd_gender
),
sales_summary AS (
    SELECT 
        d_year,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM web_sales
    INNER JOIN date_dim ON web_sales.ws_sold_date_sk = date_dim.d_date_sk
    GROUP BY d_year
)
SELECT 
    a.ca_state,
    a.unique_addresses,
    a.avg_street_name_length,
    a.san_city_count,
    c.cd_gender,
    c.customer_count,
    c.avg_dependents,
    c.total_purchase_estimate,
    s.d_year,
    s.total_sales,
    s.total_profit
FROM address_stats a
JOIN customer_stats c ON a.ca_state = 'CA' 
JOIN sales_summary s ON s.d_year = EXTRACT(YEAR FROM cast('2002-10-01' as date))
ORDER BY a.unique_addresses DESC, c.customer_count DESC, s.total_sales DESC;