WITH RankedAddresses AS (
    SELECT 
        ca_address_id,
        ca_city,
        ca_state,
        ca_zip,
        ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY ca_address_id) AS address_rank
    FROM 
        customer_address
    WHERE 
        ca_city IS NOT NULL 
        AND ca_state = 'CA'
),
AggregatedSales AS (
    SELECT 
        ws_ship_date_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_ship_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2001)
    GROUP BY 
        ws_ship_date_sk
),
CustomerDemographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_marital_status
)
SELECT 
    ra.ca_address_id,
    ra.ca_city,
    ra.ca_zip,
    asales.total_sales,
    asales.total_orders,
    cdemo.avg_purchase_estimate
FROM 
    RankedAddresses ra
JOIN 
    AggregatedSales asales ON ra.address_rank = 1
JOIN 
    CustomerDemographics cdemo ON cdemo.cd_gender = 'F'
WHERE 
    ra.ca_zip LIKE '9%'  
ORDER BY 
    asales.total_sales DESC, ra.ca_city;