
WITH  sales_data AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = '2022-01-01')
    GROUP BY ws_sold_date_sk, ws_item_sk
),
inventory_levels AS (
    SELECT 
        inv_date_sk,
        inv_item_sk, 
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM inventory
    GROUP BY inv_date_sk, inv_item_sk
),
demand_forecast AS (
    SELECT 
        sd.ws_item_sk,
        sd.ws_sold_date_sk,
        sd.total_sales,
        COALESCE(il.total_inventory, 0) AS total_inventory,
        ROW_NUMBER() OVER (PARTITION BY sd.ws_item_sk ORDER BY sd.ws_sold_date_sk DESC) AS rn
    FROM sales_data sd
    LEFT JOIN inventory_levels il ON sd.ws_item_sk = il.inv_item_sk
    WHERE sd.ws_sold_date_sk < (SELECT MAX(ws_sold_date_sk) FROM web_sales)
)
SELECT 
    df.ws_item_sk,
    SUM(df.total_sales) AS aggregate_sales,
    MAX(df.total_inventory) AS max_inventory,
    (SUM(df.total_sales) / NULLIF(MAX(df.total_inventory), 0)) AS sales_to_inventory_ratio
FROM demand_forecast df
WHERE df.rn <= 3
GROUP BY df.ws_item_sk
HAVING (SUM(df.total_sales) / NULLIF(MAX(df.total_inventory), 0)) IS NOT NULL
ORDER BY sales_to_inventory_ratio DESC
LIMIT 10;
