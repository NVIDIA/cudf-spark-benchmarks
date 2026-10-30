
WITH sales_data AS (
    SELECT 
        ss_store_sk,
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss_ticket_number) AS unique_sales_count,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_profit) DESC) AS rank
    FROM store_sales
    WHERE ss_sold_date_sk >= (
        SELECT MAX(d_date_sk) - 30 FROM date_dim WHERE d_year = 2023
    )
    GROUP BY ss_store_sk, ss_item_sk
),
top_sales AS (
    SELECT 
        sd.ss_store_sk,
        sd.ss_item_sk,
        sd.total_quantity,
        sd.total_net_profit,
        sd.unique_sales_count,
        ROW_NUMBER() OVER (PARTITION BY sd.ss_store_sk ORDER BY sd.total_net_profit DESC) AS top_rank
    FROM sales_data sd
)
SELECT 
    s.s_store_id,
    s.s_store_name,
    COALESCE(t.total_quantity, 0) AS total_quantity,
    COALESCE(t.total_net_profit, 0) AS total_net_profit,
    COALESCE(t.unique_sales_count, 0) AS unique_sales_count,
    (SELECT COUNT(*) 
     FROM store_returns sr 
     WHERE sr.sr_store_sk = s.s_store_sk AND sr.sr_return_quantity > 0) AS total_returns,
    (SELECT AVG(ws.ws_net_profit) 
     FROM web_sales ws 
     WHERE ws.ws_item_sk = t.ss_item_sk 
     AND ws.ws_ship_date_sk BETWEEN (
        SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023
     ) AND (
        SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023
     )
    ) AS avg_web_net_profit
FROM store s
LEFT JOIN top_sales t ON s.s_store_sk = t.ss_store_sk AND t.top_rank <= 5
WHERE s.s_state = 'CA'
ORDER BY total_net_profit DESC NULLS LAST;
