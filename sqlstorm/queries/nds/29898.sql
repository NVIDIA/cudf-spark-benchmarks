
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type), 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', TRIM(ca_suite_number)) ELSE '' END) AS full_address,
        LOWER(ca_city) AS city_lower,
        UPPER(ca_state) AS state_upper
    FROM 
        customer_address
), filtered_demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count
    FROM 
        customer_demographics
    WHERE 
        cd_purchase_estimate > 1000 AND cd_gender = 'M'
), sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        AVG(ws_sales_price) AS avg_sales_price
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
)
SELECT 
    pa.full_address,
    fd.cd_gender,
    fd.cd_marital_status,
    sd.total_quantity,
    sd.avg_sales_price
FROM 
    processed_addresses pa
JOIN 
    customer c ON c.c_current_addr_sk = pa.ca_address_sk
JOIN 
    filtered_demographics fd ON c.c_current_cdemo_sk = fd.cd_demo_sk
JOIN 
    sales_data sd ON sd.ws_item_sk = (SELECT i_item_sk FROM item WHERE i_item_id = 'ITEM0001' LIMIT 1)
WHERE 
    pa.city_lower LIKE '%new%' AND 
    pa.state_upper = 'CA'
ORDER BY 
    sd.total_quantity DESC
LIMIT 100;
