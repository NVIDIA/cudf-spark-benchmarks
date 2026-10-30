
WITH RankSales AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        ws_sales_price,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS price_rank,
        SUM(ws_quantity) OVER (PARTITION BY ws_item_sk) AS total_quantity_sold
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 1000 AND 2000
),
TopSellingItems AS (
    SELECT
        ws_item_sk,
        MAX(ws_sales_price) AS max_price,
        SUM(total_quantity_sold) AS total_quantity
    FROM RankSales
    WHERE price_rank <= 3
    GROUP BY ws_item_sk
),
EligibleItems AS (
    SELECT
        i_item_sk,
        i_item_desc,
        COALESCE(MAX(max_price), 0) AS featured_price,
        CASE 
            WHEN MAX(max_price) IS NULL THEN 'No Sales'
            WHEN COUNT(DISTINCT i_item_sk) = 0 THEN 'Not Available'
            ELSE 'Available'
        END AS availability
    FROM item
    LEFT JOIN TopSellingItems ON i_item_sk = ws_item_sk
    GROUP BY i_item_sk, i_item_desc
)
SELECT 
    ea.i_item_sk,
    ea.i_item_desc,
    ea.featured_price,
    ea.availability,
    COALESCE((SELECT SUM(sr_return_quantity) FROM store_returns WHERE sr_item_sk = ea.i_item_sk), 0) AS total_returns,
    CASE
        WHEN ea.featured_price > 100 THEN 'Expensive Item'
        ELSE 'Cheap Item'
    END AS price_category
FROM EligibleItems ea
WHERE ea.availability <> 'No Sales'
AND EXISTS (
    SELECT 1
    FROM catalog_sales cs
    WHERE cs.cs_item_sk = ea.i_item_sk
    HAVING COUNT(cs.cs_order_number) > 5
)
ORDER BY ea.featured_price DESC, total_returns ASC
LIMIT 10;
