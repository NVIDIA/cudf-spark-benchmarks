
WITH SalesData AS (
    SELECT 
        w.w_warehouse_name,
        s.s_store_name,
        i.i_item_desc,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        store s ON ws.ws_ship_addr_sk = s.s_store_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2458832 AND 2458839 
    GROUP BY 
        w.w_warehouse_name, s.s_store_name, i.i_item_desc
    HAVING 
        SUM(ws.ws_sales_price * ws.ws_quantity) > 1000
),
RankedSales AS (
    SELECT 
        w_warehouse_name, 
        s_store_name, 
        i_item_desc, 
        total_quantity, 
        total_sales, 
        total_orders,
        RANK() OVER (PARTITION BY w_warehouse_name ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesData
)
SELECT 
    w_warehouse_name, 
    s_store_name, 
    i_item_desc, 
    total_quantity, 
    total_sales, 
    total_orders
FROM 
    RankedSales
WHERE 
    sales_rank <= 3 
ORDER BY 
    w_warehouse_name, total_sales DESC;
