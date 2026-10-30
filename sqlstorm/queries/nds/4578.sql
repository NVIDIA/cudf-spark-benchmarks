
WITH ranked_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rank_sales,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS total_quantity
    FROM web_sales ws
    WHERE ws.ws_ship_date_sk >= 2450000
),
top_items AS (
    SELECT
        item.i_item_id,
        item.i_item_desc,
        cs.total_quantity,
        cs.ws_sales_price
    FROM ranked_sales cs
    JOIN item ON cs.ws_item_sk = item.i_item_sk
    WHERE cs.rank_sales <= 5
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_country,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_country ORDER BY cd.cd_purchase_estimate DESC) AS rank_country
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    ci.c_customer_id,
    ci.cd_gender,
    ci.cd_marital_status,
    ti.i_item_id,
    ti.i_item_desc,
    ti.total_quantity,
    ci.ca_country
FROM
    customer_info ci
JOIN top_items ti ON ci.c_customer_id = (
    SELECT 
        CASE 
            WHEN COUNT(*) = 1 THEN MIN(c.c_customer_id)
            ELSE NULL 
        END
    FROM customer c
    WHERE c.c_current_cdemo_sk IN (
        SELECT DISTINCT c.cd_demo_sk 
        FROM customer_demographics c 
        WHERE c.cd_purchase_estimate > (SELECT AVG(cd_purchase_estimate) FROM customer_demographics)
    )
)
WHERE 
    ci.rank_country <= 3 AND
    (ci.cd_gender = 'F' OR ci.cd_marital_status = 'S')
ORDER BY 
    ti.total_quantity DESC, 
    ci.c_customer_id;
