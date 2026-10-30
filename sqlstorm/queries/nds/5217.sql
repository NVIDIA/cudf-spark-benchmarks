
WITH SalesData AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        w.w_warehouse_id AS warehouse_id,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(DISTINCT cs.cs_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        catalog_sales cs ON ws.ws_item_sk = cs.cs_item_sk
    WHERE 
        d.d_year BETWEEN 2019 AND 2023
    GROUP BY 
        d.d_year, d.d_month_seq, w.w_warehouse_id
),
WarehouseSales AS (
    SELECT
        warehouse_id,
        SUM(total_sales) AS warehouse_total_sales,
        SUM(total_orders) AS warehouse_total_orders,
        AVG(avg_sales_price) AS warehouse_avg_sales_price,
        AVG(avg_net_profit) AS warehouse_avg_net_profit
    FROM 
        SalesData
    GROUP BY 
        warehouse_id
)
SELECT 
    ws.warehouse_id,
    ws.warehouse_total_sales,
    ws.warehouse_total_orders,
    ws.warehouse_avg_sales_price,
    ws.warehouse_avg_net_profit
FROM 
    WarehouseSales ws
ORDER BY 
    ws.warehouse_total_sales DESC
LIMIT 10;
