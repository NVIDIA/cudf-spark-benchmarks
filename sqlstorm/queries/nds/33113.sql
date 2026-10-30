
WITH RecursiveSales AS (
    SELECT ws_item_sk, SUM(ws_quantity) AS total_web_sales, ws_sales_price
    FROM web_sales
    GROUP BY ws_item_sk, ws_sales_price
),
StoreSales AS (
    SELECT ss_item_sk, SUM(ss_quantity) AS total_store_sales, ss_sales_price
    FROM store_sales
    GROUP BY ss_item_sk, ss_sales_price
),
CombinedSales AS (
    SELECT 
        COALESCE(ws.ws_item_sk, ss.ss_item_sk) AS item_sk,
        COALESCE(ws.total_web_sales, 0) AS total_web_sales,
        COALESCE(ss.total_store_sales, 0) AS total_store_sales,
        (COALESCE(ws.total_web_sales, 0) + COALESCE(ss.total_store_sales, 0)) AS total_sales,
        (COALESCE(ws.total_web_sales, 0) * 1.2) AS estimated_web_revenue,
        (COALESCE(ss.total_store_sales, 0) * 1.2) AS estimated_store_revenue
    FROM RecursiveSales ws
    FULL OUTER JOIN StoreSales ss ON ws.ws_item_sk = ss.ss_item_sk
),
ItemsAboveThreshold AS (
    SELECT item_sk, total_sales, estimated_web_revenue, estimated_store_revenue
    FROM CombinedSales
    WHERE total_sales > 1000
)

SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(c.total_sales, 0) AS total_sales,
    COALESCE(c.estimated_web_revenue, 0) AS estimated_web_revenue,
    COALESCE(c.estimated_store_revenue, 0) AS estimated_store_revenue,
    ROW_NUMBER() OVER (ORDER BY COALESCE(c.total_sales, 0) DESC) AS sales_rank
FROM item i
LEFT JOIN ItemsAboveThreshold c ON i.i_item_sk = c.item_sk
WHERE i.i_current_price IS NOT NULL
ORDER BY sales_rank
LIMIT 50;
