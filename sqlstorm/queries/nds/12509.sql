
WITH SalesData AS (
    SELECT 
        ws.ws_order_number,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_item_sk) AS item_count,
        COUNT(DISTINCT ws.ws_ship_customer_sk) AS customer_count
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_order_number
)

SELECT 
    total_sales,
    item_count,
    customer_count
FROM 
    SalesData
ORDER BY 
    total_sales DESC
LIMIT 100;
