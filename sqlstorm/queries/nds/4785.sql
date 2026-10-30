
WITH sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_ship_mode_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS item_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_ship_mode_sk, ws.ws_item_sk
),
warehouse_sales AS (
    SELECT 
        inv.inv_warehouse_sk,
        SUM(cs.cs_quantity) AS total_catalog_quantity,
        SUM(cs.cs_net_profit) AS total_catalog_profit
    FROM 
        inventory inv
    JOIN 
        catalog_sales cs ON inv.inv_item_sk = cs.cs_item_sk
    GROUP BY 
        inv.inv_warehouse_sk
)
SELECT 
    d.d_date AS sale_date,
    sm.sm_ship_mode_id,
    sd.total_quantity,
    sd.total_profit,
    COALESCE(ws.total_catalog_quantity, 0) AS catalog_quantity,
    COALESCE(ws.total_catalog_profit, 0) AS catalog_profit
FROM 
    sales_data sd
JOIN 
    date_dim d ON sd.ws_sold_date_sk = d.d_date_sk
LEFT JOIN 
    ship_mode sm ON sd.ws_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN 
    warehouse_sales ws ON sd.ws_item_sk = ws.inv_warehouse_sk
WHERE 
    d.d_year = 2023 
    AND (sm.sm_carrier IS NULL OR sm.sm_carrier != 'FedEx')
    AND sd.item_rank <= 10
ORDER BY 
    d.d_date, total_profit DESC;
