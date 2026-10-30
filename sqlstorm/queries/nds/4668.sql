WITH SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_web_site_sk,
        w.w_warehouse_name,
        d.d_year,
        d.d_month_seq,
        d.d_week_seq,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_quantity DESC) AS rnk
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2001
        AND ws.ws_sales_price > (
            SELECT 
                AVG(ws2.ws_sales_price)
            FROM 
                web_sales ws2
            WHERE 
                ws2.ws_item_sk = ws.ws_item_sk
        )
),
TopSales AS (
    SELECT 
        sd.ws_order_number,
        sd.ws_item_sk,
        sd.ws_sales_price,
        sd.ws_quantity,
        sd.w_warehouse_name,
        sd.d_year,
        sd.d_month_seq,
        sd.d_week_seq
    FROM 
        SalesData sd
    WHERE 
        sd.rnk <= 5
)
SELECT 
    ts.w_warehouse_name,
    COUNT(ts.ws_order_number) AS total_orders,
    SUM(ts.ws_sales_price * ts.ws_quantity) AS total_sales,
    AVG(ts.ws_sales_price) AS avg_sales_price,
    MAX(ts.ws_sales_price) AS max_sales_price,
    MIN(ts.ws_sales_price) AS min_sales_price
FROM 
    TopSales ts
GROUP BY 
    ts.w_warehouse_name
ORDER BY 
    total_sales DESC
LIMIT 10;