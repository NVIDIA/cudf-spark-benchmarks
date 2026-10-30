
WITH SalesSummary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2451545 AND 2451560 
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        ws_item_sk AS ss_item_sk,
        total_quantity,
        total_profit,
        order_count,
        RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
    FROM 
        SalesSummary
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    ti.total_quantity,
    ti.total_profit,
    ti.order_count,
    CASE
        WHEN ti.order_count IS NULL THEN 'No Orders'
        ELSE CONCAT('Rank ', ti.profit_rank)
    END AS ranking
FROM 
    TopItems ti
JOIN 
    item i ON ti.ss_item_sk = i.i_item_sk
LEFT JOIN 
    store_sales ss ON ti.ss_item_sk = ss.ss_item_sk AND ss.ss_sold_date_sk BETWEEN 2451545 AND 2451560
WHERE 
    ti.profit_rank <= 10
ORDER BY 
    ti.total_profit DESC;
