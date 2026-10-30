WITH SalesData AS (
    SELECT 
        w.w_warehouse_id,
        sm.sm_type,
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2458000 AND 2459000 
    GROUP BY 
        w.w_warehouse_id, sm.sm_type, i.i_item_id
), AvgSales AS (
    SELECT 
        w_warehouse_id, 
        sm_type, 
        AVG(total_sales) AS avg_sales, 
        AVG(total_quantity) AS avg_quantity,
        AVG(total_discount) AS avg_discount,
        SUM(total_orders) AS total_order_count
    FROM 
        SalesData
    GROUP BY 
        w_warehouse_id, sm_type
)
SELECT 
    asd.w_warehouse_id,
    asd.sm_type,
    asd.avg_sales,
    asd.avg_quantity,
    asd.avg_discount,
    asd.total_order_count,
    ca.ca_city,
    ca.ca_state 
FROM 
    AvgSales asd
JOIN 
    customer_address ca ON asd.w_warehouse_id = ca.ca_address_id 
WHERE 
    asd.avg_sales > 1000
ORDER BY 
    asd.avg_sales DESC
LIMIT 100;