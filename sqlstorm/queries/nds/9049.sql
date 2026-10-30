
WITH SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount,
        ws_ship_mode_sk
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk, ws_ship_mode_sk
),
WarehouseStats AS (
    SELECT 
        w.w_warehouse_sk, 
        w.w_warehouse_name, 
        COUNT(DISTINCT sd.ws_item_sk) AS items_sold,
        AVG(sd.total_quantity) AS avg_quantity_per_item,
        SUM(sd.total_sales) AS total_sales_amount,
        sd.ws_ship_mode_sk
    FROM 
        SalesData AS sd
    JOIN 
        inventory AS inv ON sd.ws_item_sk = inv.inv_item_sk
    JOIN 
        warehouse AS w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_sk, w.w_warehouse_name, sd.ws_ship_mode_sk
)
SELECT 
    ws.w_warehouse_name AS warehouse_name,
    ws.items_sold,
    ws.avg_quantity_per_item,
    ws.total_sales_amount,
    sm.sm_type AS shipping_method
FROM 
    WarehouseStats AS ws
JOIN 
    ship_mode AS sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
ORDER BY 
    ws.total_sales_amount DESC
LIMIT 10;
