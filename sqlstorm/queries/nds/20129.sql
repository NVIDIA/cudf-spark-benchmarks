WITH  SalesTimeline AS (
    SELECT 
        ws_sold_date_sk,
        sum(ws_net_profit) OVER (PARTITION BY ws_sold_date_sk ORDER BY ws_sold_date_sk) AS cumulative_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_sold_date_sk ORDER BY ws_net_profit DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_net_profit IS NOT NULL
),
RankedSales AS (
    SELECT 
        ws_item_sk, 
        ws_quantity, 
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_net_profit > (SELECT AVG(ws_net_profit) FROM web_sales W WHERE ws_item_sk = W.ws_item_sk)
)

SELECT 
    s_day.d_date AS sales_date,
    SUM(r.ws_quantity) AS total_quantity,
    COUNT(DISTINCT r.ws_item_sk) AS unique_items_sold,
    MAX(s.tot_net_profit) AS max_net_profit,
    COALESCE(AVG(r.ws_net_profit), 0) AS avg_net_profit
FROM 
    date_dim s_day
LEFT JOIN (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_net_profit) AS tot_net_profit
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk
) s ON s_day.d_date_sk = s.ws_sold_date_sk
JOIN RankedSales r ON r.ws_item_sk IN (
    SELECT 
        i_item_sk 
    FROM 
        item 
    WHERE 
        i_current_price BETWEEN 10 AND 100
)
WHERE 
    s_day.d_date BETWEEN '2000-01-01' AND '2000-12-31'
    AND s_day.d_dow IN (0, 6) 
GROUP BY 
    s_day.d_date
ORDER BY 
    sales_date DESC;