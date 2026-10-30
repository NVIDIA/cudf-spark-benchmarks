
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL AND ca_suite_number <> '' 
                    THEN CONCAT(' Suite ', ca_suite_number) 
                    ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
GenderStatistics AS (
    SELECT 
        cd_gender,
        COUNT(c.c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender
),
DateAggregate AS (
    SELECT 
        d_year,
        COUNT(ws_order_number) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d_year
)
SELECT 
    ad.full_address,
    ad.ca_city,
    ad.ca_state,
    ad.ca_zip,
    ad.ca_country,
    gs.cd_gender,
    gs.customer_count,
    gs.avg_purchase_estimate,
    da.d_year,
    da.total_sales,
    da.total_profit
FROM 
    AddressDetails ad
JOIN 
    GenderStatistics gs ON ad.ca_state = 'CA'  
JOIN 
    DateAggregate da ON da.total_sales > 1000  
ORDER BY 
    da.total_profit DESC, gs.customer_count DESC
LIMIT 50;
