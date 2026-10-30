
WITH address_counts AS (
    SELECT 
        ca_state,
        COUNT(*) AS state_count,
        AVG(LENGTH(ca_street_name)) AS avg_street_length,
        SUM(CASE WHEN ca_city LIKE '%city%' THEN 1 ELSE 0 END) AS city_mentions
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
demographics AS (
    SELECT 
        cd_gender,
        COUNT(*) AS gender_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
sales_data AS (
    SELECT 
        sm.sm_type,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        sm.sm_type
)
SELECT 
    ac.ca_state,
    ac.state_count,
    ac.avg_street_length,
    ac.city_mentions,
    d.cd_gender,
    d.gender_count,
    d.avg_purchase_estimate,
    sd.sm_type,
    sd.total_sales,
    sd.order_count
FROM 
    address_counts ac
CROSS JOIN 
    demographics d
CROSS JOIN 
    sales_data sd
ORDER BY 
    ac.state_count DESC, d.gender_count DESC, sd.total_sales DESC
LIMIT 100;
