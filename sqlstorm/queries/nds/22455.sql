
WITH ranked_sales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ws_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS profit_rank,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_quantity DESC) AS quantity_rank
    FROM web_sales
    WHERE ws_sales_price > 0 
    AND ws_quantity IS NOT NULL
),
item_sales AS (
    SELECT 
        item.i_item_sk,
        item.i_item_id,
        COALESCE(SUM(ws.ws_quantity), 0) AS total_quantity,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM item
    LEFT JOIN web_sales ws ON item.i_item_sk = ws.ws_item_sk
    GROUP BY item.i_item_sk, item.i_item_id
)
SELECT 
    isa.i_item_id,
    isa.total_quantity,
    isa.total_net_profit,
    CASE WHEN isa.total_net_profit = 0 THEN 'No Profit' 
         ELSE CAST(ROUND((isa.total_net_profit / NULLIF(isa.total_quantity, 0)), 2) AS STRING) END AS avg_profit_per_unit,
    CASE 
        WHEN EXISTS (SELECT 1 FROM customer c 
                     WHERE c.c_first_name IS NULL OR c.c_last_name IS NULL) THEN 'Some Customers Missing Names' 
        ELSE 'All Customers Named' 
    END AS customer_name_status
FROM item_sales isa
LEFT JOIN ranked_sales rs ON isa.i_item_sk = rs.ws_item_sk
WHERE rs.profit_rank <= 5 OR (rs.profit_rank IS NULL AND rs.quantity_rank = 1)
ORDER BY isa.total_net_profit DESC
LIMIT 10;
