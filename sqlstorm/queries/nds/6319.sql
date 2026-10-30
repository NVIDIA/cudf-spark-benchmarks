WITH sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk 
    WHERE 
        d.d_year = 2001 AND 
        d.d_moy IN (11, 12)  
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
ranking AS (
    SELECT 
        ws_item_sk,
        total_quantity,
        total_sales,
        total_orders,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_data
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    r.total_quantity,
    r.total_sales,
    r.total_orders,
    r.sales_rank
FROM 
    ranking r
JOIN 
    item i ON r.ws_item_sk = i.i_item_sk
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.total_sales DESC;