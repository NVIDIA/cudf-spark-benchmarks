
WITH  sales_hierarchy AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
    UNION ALL
    SELECT 
        cs_item_sk, 
        SUM(cs_quantity) AS total_quantity, 
        SUM(cs_net_profit) AS total_profit
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        cs_item_sk
), ranked_sales AS (
    SELECT 
        s.ws_item_sk,
        COALESCE(s.total_quantity, 0) AS total_quantity,
        COALESCE(s.total_profit, 0) AS total_profit,
        DENSE_RANK() OVER (ORDER BY COALESCE(s.total_profit, 0) DESC) AS profit_rank
    FROM 
        sales_hierarchy s
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    r.total_quantity,
    r.total_profit,
    r.profit_rank
FROM 
    ranked_sales r
JOIN 
    item i ON r.ws_item_sk = i.i_item_sk
LEFT JOIN 
    store_returns sr ON sr.sr_item_sk = r.ws_item_sk
WHERE 
    (r.total_profit > 1000 OR r.total_quantity > 100)
    AND r.profit_rank < 50
ORDER BY 
    r.total_profit DESC
LIMIT 10;
