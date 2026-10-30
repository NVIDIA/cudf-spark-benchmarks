
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2401 AND 2405
),
Summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price * ws_quantity) AS total_sales,
        AVG(ws_sales_price) AS avg_sales_price
    FROM web_sales
    GROUP BY ws_item_sk
),
TopItems AS (
    SELECT 
        s.ws_item_sk, 
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM Summary s
    WHERE total_sales > 1000
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(rp.rank, 0) AS rank,
    s.total_sales,
    s.avg_sales_price
FROM item i
LEFT JOIN RankedSales rp ON i.i_item_sk = rp.ws_item_sk AND rp.rank = 1
JOIN Summary s ON i.i_item_sk = s.ws_item_sk
JOIN TopItems t ON s.ws_item_sk = t.ws_item_sk
WHERE i.i_current_price IS NOT NULL 
  AND (s.total_sales > 5000 OR s.avg_sales_price > 100)
ORDER BY total_sales DESC, avg_sales_price DESC
LIMIT 10;
