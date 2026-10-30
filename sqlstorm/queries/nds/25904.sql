
WITH AddressDetails AS (
    SELECT 
        ca_state, 
        COUNT(DISTINCT ca_address_id) AS unique_addresses, 
        SUM(CASE WHEN ca_city LIKE '%ville%' THEN 1 ELSE 0 END) AS ville_count,
        SUM(CASE WHEN ca_street_type = 'St' THEN 1 ELSE 0 END) AS street_count
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
Demographics AS (
    SELECT 
        cd_gender, 
        COUNT(DISTINCT cd_demo_sk) AS demographics_count, 
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics
    WHERE 
        cd_education_status LIKE '%Graduate%'
    GROUP BY 
        cd_gender
),
SalesData AS (
    SELECT 
        d.d_year,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales 
    JOIN 
        date_dim d ON ws_sold_date_sk = d_date_sk
    WHERE 
        d.d_year > 2020
    GROUP BY 
        d.d_year
)
SELECT 
    ad.ca_state,
    ad.unique_addresses,
    ad.ville_count,
    ad.street_count,
    dem.cd_gender,
    dem.demographics_count,
    dem.avg_purchase_estimate,
    sd.d_year,
    sd.total_sales,
    sd.total_discount,
    sd.total_profit
FROM 
    AddressDetails ad
JOIN 
    Demographics dem ON ad.unique_addresses > 50
JOIN 
    SalesData sd ON sd.total_sales > 1000000
ORDER BY 
    ad.ca_state, dem.cd_gender, sd.d_year DESC;
