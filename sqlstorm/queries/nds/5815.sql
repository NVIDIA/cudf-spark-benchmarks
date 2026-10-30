WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2001 
        AND dd.d_month_seq IN (5, 6) 
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    SUM(sd.total_quantity) AS total_quantity,
    SUM(sd.total_sales) AS total_sales,
    AVG(sd.total_quantity) AS avg_quantity_per_order,
    AVG(sd.total_sales) AS avg_sales_per_order
FROM 
    SalesData sd
JOIN 
    item i ON sd.ws_item_sk = i.i_item_sk
GROUP BY 
    i.i_item_id, i.i_item_desc
ORDER BY 
    total_sales DESC
LIMIT 10;