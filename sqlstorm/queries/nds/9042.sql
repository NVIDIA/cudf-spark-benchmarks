
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
),
HighestSales AS (
    SELECT 
        r.ws_item_sk,
        MAX(r.ws_sales_price) AS max_sales_price
    FROM 
        RankedSales r
    WHERE 
        r.sales_rank <= 10
    GROUP BY 
        r.ws_item_sk
)
SELECT 
    ia.i_item_id,
    ia.i_product_name,
    hs.max_sales_price,
    COUNT(ws.ws_order_number) AS order_count,
    SUM(ws.ws_net_profit) AS total_net_profit
FROM 
    item ia
JOIN 
    HighestSales hs ON ia.i_item_sk = hs.ws_item_sk
JOIN 
    web_sales ws ON hs.ws_item_sk = ws.ws_item_sk
GROUP BY 
    ia.i_item_id, ia.i_product_name, hs.max_sales_price
ORDER BY 
    total_net_profit DESC
LIMIT 20;
