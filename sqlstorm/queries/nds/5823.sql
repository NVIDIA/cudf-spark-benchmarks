
WITH sales_data AS (
    SELECT 
        ws.ws_sold_date_sk, 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_quantity, 
        SUM(ws.ws_net_paid) AS total_net_paid
    FROM 
        web_sales ws
    INNER JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year BETWEEN 2019 AND 2021
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
top_items AS (
    SELECT 
        total_quantity, 
        total_net_paid, 
        ROW_NUMBER() OVER (ORDER BY total_net_paid DESC) AS ranking,
        ws_item_sk
    FROM 
        sales_data
)
SELECT 
    ti.total_quantity, 
    ti.total_net_paid, 
    i.i_item_desc, 
    i.i_current_price
FROM 
    top_items ti
INNER JOIN 
    item i ON ti.ws_item_sk = i.i_item_sk
WHERE 
    ti.ranking <= 10
ORDER BY 
    ti.total_net_paid DESC;
