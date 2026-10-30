
WITH AddressDetails AS (
    SELECT 
        ca_country,
        ca_city,
        ca_state,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        COUNT(DISTINCT ca_address_sk) AS address_count
    FROM 
        customer_address
    GROUP BY 
        ca_country, ca_city, ca_state, ca_street_number, ca_street_name, ca_street_type
),
Demographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        cd_education_status,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(cd_demo_sk) AS demo_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_marital_status, cd_education_status
),
SalesData AS (
    SELECT 
        d_year,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales 
    INNER JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY 
        d_year
)
SELECT 
    ad.ca_country,
    ad.ca_city,
    ad.ca_state,
    ad.full_address,
    ad.address_count,
    dm.cd_gender,
    dm.cd_marital_status,
    dm.cd_education_status,
    dm.avg_purchase_estimate,
    dm.demo_count,
    sd.d_year,
    sd.total_net_profit,
    sd.total_orders
FROM 
    AddressDetails ad
JOIN 
    Demographics dm ON ad.ca_country = dm.cd_gender
JOIN 
    SalesData sd ON ad.address_count = sd.total_orders
WHERE 
    ad.address_count > 5 AND 
    dm.avg_purchase_estimate > 500
ORDER BY 
    sd.total_net_profit DESC, 
    ad.address_count DESC;
