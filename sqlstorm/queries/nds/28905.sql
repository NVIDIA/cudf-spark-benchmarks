WITH AddressDetails AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        SUM(LENGTH(ca_street_name)) AS total_street_name_length
    FROM customer_address
    GROUP BY ca_city, ca_state
),
CustomerDemographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(*) AS demographic_count
    FROM customer_demographics
    GROUP BY cd_gender, cd_marital_status
),
SalesData AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_quantity) AS total_quantity,
        AVG(ws_net_profit) AS avg_net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq
)
SELECT 
    ad.ca_city,
    ad.ca_state,
    ad.unique_addresses,
    cd.avg_purchase_estimate,
    sd.total_sales,
    sd.total_quantity,
    sd.avg_net_profit
FROM AddressDetails ad
JOIN CustomerDemographics cd ON ad.ca_state = 'CA' 
JOIN SalesData sd ON sd.d_year = 2001 
ORDER BY ad.ca_city, ad.ca_state;