
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_item_sk
),
FilteredItems AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        CASE 
            WHEN i.i_current_price > 100 THEN 'Premium' 
            WHEN i.i_current_price BETWEEN 50 AND 100 THEN 'Standard' 
            ELSE 'Budget' 
        END AS price_category
    FROM item i
),
TopItems AS (
    SELECT fi.i_item_sk, fi.i_item_desc, fi.price_category, rs.total_quantity, rs.total_profit
    FROM FilteredItems fi
    JOIN RankedSales rs ON fi.i_item_sk = rs.ws_item_sk
    WHERE rs.profit_rank <= 10
)
SELECT 
    ti.i_item_desc AS item_description,
    ti.price_category,
    COALESCE(MAX(ti.total_quantity), 0) AS max_quantity,
    COALESCE(MIN(ti.total_profit), 0) AS min_profit,
    COUNT(ti.i_item_sk) AS rank_count
FROM TopItems ti
LEFT JOIN customer c ON c.c_customer_sk = (SELECT MIN(c_customer_sk) FROM customer WHERE c_current_cdemo_sk IS NOT NULL)
WHERE ti.price_category IS NOT NULL
GROUP BY 
    ti.i_item_desc, 
    ti.price_category
HAVING 
    COUNT(ti.i_item_sk) > 1 AND 
    SUM(ti.total_profit) > 1000
UNION ALL
SELECT 
    'Not Applicable' AS item_description,
    'N/A' AS price_category,
    MAX(ws_quantity) AS max_quantity,
    MIN(ws_net_profit) AS min_profit,
    NULL AS rank_count
FROM web_sales ws
WHERE ws_sold_date_sk IS NULL
ORDER BY price_category, max_quantity DESC;
