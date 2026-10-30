
WITH address_stats AS (
    SELECT 
        ca_state, 
        COUNT(*) AS total_addresses,
        COUNT(DISTINCT ca_city) AS unique_cities,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        MIN(LENGTH(ca_street_name)) AS min_street_name_length
    FROM customer_address
    GROUP BY ca_state
),
demographics_stats AS (
    SELECT 
        cd_marital_status, 
        COUNT(*) AS total_demographics,
        AVG(cd_dep_count) AS avg_dep_count,
        COUNT(DISTINCT cd_gender) AS unique_genders,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer_demographics
    GROUP BY cd_marital_status
),
sales_stats AS (
    SELECT 
        CASE 
            WHEN ws_net_paid < 50 THEN 'Low'
            WHEN ws_net_paid BETWEEN 50 AND 150 THEN 'Medium'
            ELSE 'High' 
        END AS sales_category,
        COUNT(*) AS sales_count,
        SUM(ws_net_paid) AS total_sales,
        AVG(ws_net_paid) AS avg_sales_value
    FROM web_sales
    GROUP BY sales_category
)

SELECT 
    a.ca_state,
    a.total_addresses,
    a.unique_cities,
    a.avg_street_name_length,
    a.max_street_name_length,
    a.min_street_name_length,
    d.cd_marital_status,
    d.total_demographics,
    d.avg_dep_count,
    d.unique_genders,
    d.avg_purchase_estimate,
    s.sales_category,
    s.sales_count,
    s.total_sales,
    s.avg_sales_value
FROM address_stats a
JOIN demographics_stats d ON a.total_addresses > 100
JOIN sales_stats s ON s.sales_count > 50
ORDER BY a.ca_state, d.cd_marital_status, s.sales_category;
