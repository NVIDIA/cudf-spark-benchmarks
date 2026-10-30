
WITH  address_parts AS (
    SELECT DISTINCT 
        ca_address_sk, 
        ca_street_number || ' ' || ca_street_name || ' ' || ca_street_type AS full_address
    FROM customer_address
), customer_info AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        ad.full_address
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN address_parts ad ON c.c_current_addr_sk = ad.ca_address_sk
), sales_data AS (
    SELECT 
        ws.ws_ship_date_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM web_sales ws
    GROUP BY ws.ws_ship_date_sk
), final_results AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        sd.ws_ship_date_sk,
        sd.total_sales,
        sd.total_orders
    FROM customer_info ci
    JOIN sales_data sd ON ci.c_customer_sk = sd.ws_ship_date_sk
)
SELECT 
    fr.full_name,
    fr.cd_gender,
    fr.cd_marital_status,
    fr.total_sales,
    fr.total_orders
FROM final_results fr
WHERE fr.total_sales > 1000
ORDER BY fr.total_sales DESC, fr.full_name ASC
LIMIT 50;
