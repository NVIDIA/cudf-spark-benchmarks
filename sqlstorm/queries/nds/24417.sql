
WITH  sales_data AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_profit,
        cd.cd_gender,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) as rn
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year IS NOT NULL
),
aggregated_data AS (
    SELECT
        sd.ws_item_sk,
        SUM(sd.ws_net_profit) AS total_net_profit,
        AVG(sd.ws_sales_price) AS avg_sales_price,
        COUNT(*) AS total_sales_count,
        MAX(sd.ws_quantity) AS max_quantity
    FROM 
        sales_data sd
    WHERE 
        sd.rn <= 5
    GROUP BY 
        sd.ws_item_sk
),
inventory_data AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
)
SELECT 
    ad.ws_item_sk,
    ad.total_net_profit,
    ad.avg_sales_price,
    COALESCE(id.total_inventory, 0) AS total_inventory_on_hand,
    CASE 
        WHEN ad.total_sales_count > 10 AND ad.avg_sales_price > 50 THEN 'High Value'
        WHEN ad.total_sales_count <= 10 AND ad.total_net_profit < 100 THEN 'Low Value'
        ELSE 'Medium Value'
    END AS sales_category,
    (
        SELECT MAX(ws_ext_sales_price)
        FROM web_sales 
        WHERE (ws_item_sk = ad.ws_item_sk) AND 
              (ws_net_paid_inc_ship_tax IS NOT NULL)
    ) AS max_web_sales_price
FROM 
    aggregated_data ad
LEFT JOIN 
    inventory_data id ON ad.ws_item_sk = id.inv_item_sk
WHERE 
    ad.total_net_profit IS NOT NULL
    AND ad.total_sales_count > 5
ORDER BY 
    ad.total_net_profit DESC;

