
WITH  sales_cte AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk) AS rn
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 20220101 AND 20221231
),
avg_sales AS (
    SELECT 
        ws_item_sk,
        AVG(ws_ext_sales_price) AS avg_price,
        SUM(ws_quantity) AS total_quantity
    FROM sales_cte
    GROUP BY ws_item_sk
),
high_sales AS (
    SELECT 
        ws_item_sk,
        avg_price,
        total_quantity
    FROM avg_sales
    WHERE total_quantity > 100
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    hs.avg_price,
    hs.total_quantity,
    COALESCE(sa.return_amt, 0) AS total_returns,
    (hs.total_quantity - COALESCE(sa.return_amt, 0)) AS net_sales
FROM high_sales hs
JOIN item i ON hs.ws_item_sk = i.i_item_sk
LEFT JOIN (
    SELECT 
        cr_item_sk,
        SUM(cr_return_amount) AS return_amt
    FROM catalog_returns
    GROUP BY cr_item_sk
) sa ON hs.ws_item_sk = sa.cr_item_sk
ORDER BY net_sales DESC
LIMIT 10;
