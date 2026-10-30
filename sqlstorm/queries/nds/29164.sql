
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        REPLACE(UPPER(c.c_email_address), '.', '@') AS obfuscated_email
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        LOWER(i.i_brand) AS brand,
        i.i_current_price,
        SUBSTRING(i.i_item_desc, 1, 50) AS description_snippet
    FROM item i
),
SalesDetails AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
)

SELECT 
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.ca_city,
    cd.ca_state,
    id.i_product_name,
    id.brand,
    id.description_snippet,
    sd.total_quantity,
    sd.total_profit,
    DENSE_RANK() OVER (PARTITION BY cd.ca_city ORDER BY sd.total_profit DESC) AS city_rank
FROM CustomerDetails cd
JOIN SalesDetails sd ON cd.c_customer_sk = sd.ws_item_sk
JOIN ItemDetails id ON sd.ws_item_sk = id.i_item_sk
WHERE cd.cd_gender = 'F'
AND cd.ca_country = 'USA'
AND sd.total_quantity > 100
ORDER BY cd.ca_state, cd.ca_city, sd.total_profit DESC;
