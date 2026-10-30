
WITH  sales_data AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_quantity,
        ws_ext_sales_price,
        ws_ship_date_sk,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number DESC) as rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (
            SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023
        )
), 
address_data AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(*) AS total_addresses
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state
), 
demographics_data AS (
    SELECT 
        cd_gender,
        COUNT(*) AS gender_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics
    WHERE 
        cd_marital_status = 'M'
    GROUP BY 
        cd_gender
)
SELECT 
    sd.ws_item_sk,
    sd.ws_order_number,
    sd.ws_sales_price,
    sd.ws_quantity,
    da.ca_city,
    da.ca_state,
    da.total_addresses,
    dd.cd_gender,
    dd.gender_count,
    dd.avg_purchase_estimate
FROM 
    sales_data sd
LEFT JOIN 
    address_data da ON da.total_addresses > 5
JOIN 
    demographics_data dd ON dd.gender_count > 10
WHERE 
    sd.rn = 1
    AND sd.ws_sales_price > (
        SELECT AVG(ws_sales_price) FROM web_sales
    )
ORDER BY 
    sd.ws_item_sk, sd.ws_order_number;
