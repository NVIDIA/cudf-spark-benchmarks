
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM web_sales 
    WHERE ws_sold_date_sk BETWEEN 1 AND 1000
    GROUP BY ws_sold_date_sk, ws_item_sk
    UNION ALL
    SELECT 
        sd.ws_sold_date_sk,
        sd.ws_item_sk,
        sd.total_sales + ws.ws_quantity,
        sd.total_profit + ws.ws_net_profit
    FROM sales_data sd
    JOIN web_sales ws ON sd.ws_item_sk = ws.ws_item_sk 
    WHERE ws.ws_sold_date_sk = sd.ws_sold_date_sk + 1
),
item_stats AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.total_profit, 0) AS total_profit,
        ROW_NUMBER() OVER (ORDER BY COALESCE(sd.total_profit, 0) DESC) AS profit_rank
    FROM item i
    LEFT JOIN (
        SELECT 
            ws_item_sk,
            SUM(ws_quantity) AS total_sales,
            SUM(ws_net_profit) AS total_profit
        FROM web_sales 
        GROUP BY ws_item_sk
    ) sd ON i.i_item_sk = sd.ws_item_sk
    WHERE i.i_current_price IS NOT NULL AND i.i_current_price > 0
)
SELECT 
    ia.ca_country,
    ia.ca_state,
    SUM(stats.total_sales) AS overall_sales,
    AVG(stats.total_profit) AS avg_profit,
    COUNT(DISTINCT stats.i_item_id) AS unique_items_sold
FROM customer_address ia
JOIN customer c ON ia.ca_address_sk = c.c_current_addr_sk 
JOIN item_stats stats ON stats.i_item_id IN (
    SELECT i_item_id FROM item WHERE i_item_sk IN (
        SELECT DISTINCT sr_item_sk FROM store_returns
        WHERE sr_return_quantity > 0
    )
)
LEFT JOIN store s ON s.s_store_sk = c.c_current_addr_sk 
WHERE ia.ca_country = 'USA'
GROUP BY ia.ca_country, ia.ca_state
HAVING AVG(stats.total_profit) > 1000
ORDER BY overall_sales DESC
LIMIT 10;
