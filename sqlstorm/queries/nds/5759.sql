
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
TopItems AS (
    SELECT 
        ws_item_sk, 
        MAX(total_quantity) AS max_quantity, 
        MAX(total_sales) AS max_sales
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 10
    GROUP BY 
        ws_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    w.w_warehouse_id,
    w.w_warehouse_name,
    t.t_hour,
    t.t_minute,
    SUM(ws.ws_quantity) AS total_quantity_sold,
    SUM(ws.ws_net_paid) AS total_revenue_generated,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_ext_tax) AS total_tax_collected
FROM 
    web_sales ws
JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
JOIN 
    warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN 
    time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
JOIN 
    TopItems ti ON ws.ws_item_sk = ti.ws_item_sk
GROUP BY 
    i.i_item_id, 
    i.i_item_desc, 
    w.w_warehouse_id, 
    w.w_warehouse_name, 
    t.t_hour, 
    t.t_minute
ORDER BY 
    total_revenue_generated DESC
LIMIT 50;
