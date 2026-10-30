WITH  sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2452236 AND 2452275  
    GROUP BY ws.ws_item_sk
), ranked_sales AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_profit,
        ss.rank,
        ROW_NUMBER() OVER (ORDER BY ss.total_profit DESC) AS overall_rank
    FROM sales_summary ss
    WHERE ss.total_quantity > (
        SELECT AVG(total_quantity) 
        FROM (
            SELECT SUM(ws_quantity) AS total_quantity 
            FROM web_sales 
            GROUP BY ws_item_sk
        ) AS avg_sales
    )
)
SELECT 
    i.i_item_id,
    COALESCE(SUM(ss.total_quantity), 0) AS total_sold,
    ROUND(COALESCE(SUM(ss.total_profit), 0), 2) AS total_profit,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    CASE 
        WHEN MAX(ss.rank) IS NULL THEN 'No Sales'
        ELSE 'Sales Made'
    END AS sales_status
FROM ranked_sales ss
LEFT JOIN item i ON ss.ws_item_sk = i.i_item_sk
LEFT JOIN web_sales ws ON ss.ws_item_sk = ws.ws_item_sk
GROUP BY i.i_item_id
HAVING COUNT(DISTINCT ws.ws_order_number) > 0
ORDER BY total_profit DESC, total_sold DESC
LIMIT 10;