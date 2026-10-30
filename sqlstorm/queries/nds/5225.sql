
WITH sales_summary AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        AVG(ws_sales_price) AS avg_sales_price,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
promotions_summary AS (
    SELECT 
        p.p_item_sk,
        COUNT(p.p_promo_sk) AS total_promotions
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_item_sk = ws.ws_item_sk
    WHERE 
        p.p_start_date_sk <= (SELECT MAX(ws_sold_date_sk) FROM web_sales) 
        AND p.p_end_date_sk >= (SELECT MIN(ws_sold_date_sk) FROM web_sales)
    GROUP BY 
        p.p_item_sk
),
final_summary AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_quantity,
        ss.avg_sales_price,
        ss.total_net_profit,
        COALESCE(ps.total_promotions, 0) AS total_promotions
    FROM 
        sales_summary ss
    LEFT JOIN 
        promotions_summary ps ON ss.ws_item_sk = ps.p_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    fs.total_quantity,
    fs.avg_sales_price,
    fs.total_net_profit,
    fs.total_promotions
FROM 
    final_summary fs
JOIN 
    item i ON fs.ws_item_sk = i.i_item_sk
ORDER BY 
    fs.total_net_profit DESC
LIMIT 10;
