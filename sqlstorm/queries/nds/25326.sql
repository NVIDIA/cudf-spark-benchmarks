
WITH Address_Analysis AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        COUNT(*) AS total_addresses,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        SUM(CASE 
            WHEN ca_street_type LIKE '%St%' THEN 1 
            ELSE 0 
        END) AS street_st_count
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state
),
Demographic_Summary AS (
    SELECT 
        cd_gender,
        COUNT(*) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
Sales_Analysis AS (
    SELECT 
        d_year,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_net_paid_inc_tax) AS avg_order_value
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY 
        d_year
)
SELECT 
    aa.ca_city,
    aa.ca_state,
    aa.unique_addresses,
    aa.total_addresses,
    aa.avg_street_name_length,
    aa.street_st_count,
    da.cd_gender,
    da.total_customers,
    da.avg_purchase_estimate,
    sa.d_year,
    sa.total_profit,
    sa.total_orders,
    sa.avg_order_value
FROM 
    Address_Analysis aa
JOIN 
    Demographic_Summary da ON TRUE
JOIN 
    Sales_Analysis sa ON TRUE
ORDER BY 
    aa.ca_state, 
    aa.ca_city, 
    sa.d_year DESC;
