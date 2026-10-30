
WITH SalesData AS (
    SELECT 
        w.w_warehouse_id,
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        w.w_warehouse_id, i.i_item_id
),
WarehouseTotal AS (
    SELECT 
        w.w_warehouse_id,
        SUM(sd.total_quantity) AS warehouse_quantity,
        SUM(sd.total_net_profit) AS warehouse_net_profit,
        SUM(sd.total_orders) AS warehouse_orders
    FROM 
        SalesData sd
    JOIN 
        warehouse w ON sd.w_warehouse_id = w.w_warehouse_id
    GROUP BY 
        w.w_warehouse_id
),
TopWarehouses AS (
    SELECT 
        w.w_warehouse_id,
        wt.warehouse_quantity,
        wt.warehouse_net_profit,
        wt.warehouse_orders,
        RANK() OVER (ORDER BY wt.warehouse_net_profit DESC) AS profit_rank
    FROM 
        WarehouseTotal wt
    JOIN 
        warehouse w ON wt.w_warehouse_id = w.w_warehouse_id
)
SELECT 
    tw.w_warehouse_id,
    tw.warehouse_quantity,
    tw.warehouse_net_profit,
    tw.warehouse_orders
FROM 
    TopWarehouses tw
WHERE 
    tw.profit_rank <= 5
ORDER BY 
    tw.warehouse_net_profit DESC;
