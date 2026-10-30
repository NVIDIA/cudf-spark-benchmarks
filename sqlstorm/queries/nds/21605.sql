
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk, 
        ws.ws_order_number,
        ws.ws_sales_price,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank
    FROM web_sales ws
    WHERE ws.ws_sales_price IS NOT NULL
),
CustomerReturns AS (
    SELECT 
        wr.wr_item_sk,
        COUNT(DISTINCT wr.wr_order_number) AS return_count,
        SUM(wr.wr_return_amt) AS total_return_amt
    FROM web_returns wr
    GROUP BY wr.wr_item_sk
),
OverallReturns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_cr_quantity,
        SUM(cr.cr_return_amount) AS total_cr_amount
    FROM catalog_returns cr
    GROUP BY cr.cr_item_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        COALESCE(r.return_count, 0) AS web_return_count,
        COALESCE(o.total_cr_quantity, 0) AS catalog_return_quantity
    FROM item i
    LEFT JOIN CustomerReturns r ON i.i_item_sk = r.wr_item_sk
    LEFT JOIN OverallReturns o ON i.i_item_sk = o.cr_item_sk
)
SELECT 
    id.i_item_id,
    id.i_product_name,
    RANK() OVER (ORDER BY (id.web_return_count + id.catalog_return_quantity) DESC) AS return_rank,
    CASE WHEN id.web_return_count > 5 THEN 'High Return' 
         WHEN id.web_return_count BETWEEN 2 AND 5 THEN 'Moderate Return' 
         ELSE 'Low Return' END AS return_category,
    RANK() OVER (PARTITION BY id.i_item_id ORDER BY id.web_return_count DESC) AS web_rank,
    id.web_return_count,
    (SELECT AVG(price_rank) 
     FROM RankedSales r 
     WHERE r.ws_item_sk = id.i_item_sk) AS avg_price_rank,
    (SELECT STRING_AGG(CAST(wp.wp_url AS STRING), '; ') 
     FROM web_page wp 
     WHERE wp.wp_creation_date_sk > 2023) AS recent_web_paths
FROM ItemDetails id
WHERE id.web_return_count IS NOT NULL 
  AND id.catalog_return_quantity > 0
ORDER BY return_rank, id.i_item_id
LIMIT 50;
