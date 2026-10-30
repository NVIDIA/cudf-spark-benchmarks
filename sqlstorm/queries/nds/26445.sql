
WITH Address_Stats AS (
    SELECT 
        ca_city,
        COUNT(*) AS address_count,
        AVG(COALESCE(LENGTH(ca_street_name), 0)) AS avg_street_name_length,
        SUM(CASE WHEN ca_street_type IS NOT NULL THEN 1 ELSE 0 END) AS street_type_count
    FROM 
        customer_address
    GROUP BY 
        ca_city
),
Demographics_Stats AS (
    SELECT 
        CASE 
            WHEN cd_gender = 'M' THEN 'Male'
            WHEN cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        COUNT(*) AS demographic_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(CASE WHEN cd_credit_rating = 'Good' THEN 1 ELSE 0 END) AS good_credit_count
    FROM 
        customer_demographics
    GROUP BY 
        CASE 
            WHEN cd_gender = 'M' THEN 'Male'
            WHEN cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END
),
Sales_Summary AS (
    SELECT 
        d_year,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_paid) AS total_sales,
        SUM(ws_quantity) AS total_units_sold
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY 
        d_year
)
SELECT 
    a.ca_city,
    a.address_count,
    a.avg_street_name_length,
    a.street_type_count,
    d.gender,
    d.demographic_count,
    d.avg_purchase_estimate,
    d.good_credit_count,
    s.d_year,
    s.total_orders,
    s.total_sales,
    s.total_units_sold
FROM 
    Address_Stats a
JOIN 
    Demographics_Stats d ON TRUE 
JOIN 
    Sales_Summary s ON TRUE 
ORDER BY 
    a.address_count DESC, d.demographic_count DESC, s.total_sales DESC
LIMIT 100;
