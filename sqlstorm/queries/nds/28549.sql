
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_addresses,
        COUNT(DISTINCT ca_city) AS unique_cities,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        MIN(LENGTH(ca_street_name)) AS min_street_name_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerStats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(DISTINCT cd_credit_rating) AS unique_credit_ratings
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesStats AS (
    SELECT 
        ws_ship_date_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_sales_price) AS total_sales,
        AVG(ws_quantity) AS avg_items_per_order
    FROM 
        web_sales
    WHERE 
        ws_ship_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND ws_ship_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_ship_date_sk
)
SELECT 
    ads.ca_state,
    ads.total_addresses,
    ads.unique_cities,
    ads.avg_street_name_length,
    cust.cd_gender,
    cust.total_customers,
    cust.avg_purchase_estimate,
    sales.total_orders,
    sales.total_sales,
    sales.avg_items_per_order
FROM 
    AddressStats ads
JOIN 
    CustomerStats cust ON 1=1
JOIN 
    SalesStats sales ON 1=1
ORDER BY 
    ads.total_addresses DESC, 
    cust.total_customers DESC;
