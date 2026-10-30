
WITH sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_web_page_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2022
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_web_page_sk
), 
ranked_sales AS (
    SELECT 
        ws_sold_date_sk,
        ws_web_page_sk,
        total_quantity,
        total_net_profit,
        avg_sales_price,
        total_orders,
        RANK() OVER (PARTITION BY ws_web_page_sk ORDER BY total_net_profit DESC) AS rank_profit,
        RANK() OVER (PARTITION BY ws_web_page_sk ORDER BY total_quantity DESC) AS rank_quantity
    FROM 
        sales_data
)
SELECT 
    dd.d_date AS sale_date,
    wp.wp_url AS web_page_url,
    rs.total_quantity,
    rs.total_net_profit,
    rs.avg_sales_price,
    rs.total_orders
FROM 
    ranked_sales rs
JOIN 
    web_page wp ON rs.ws_web_page_sk = wp.wp_web_page_sk
JOIN 
    date_dim dd ON rs.ws_sold_date_sk = dd.d_date_sk
WHERE 
    rs.rank_profit <= 5 AND rs.rank_quantity <= 5
ORDER BY 
    sale_date, total_net_profit DESC;
