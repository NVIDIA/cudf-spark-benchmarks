
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_quantity,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS PriceRank
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
),
AggregatedReturns AS (
    SELECT 
        cr_item_sk,
        SUM(cr_return_quantity) AS total_return_quantity,
        AVG(cr_return_amount) AS avg_return_amount,
        COUNT(DISTINCT cr_order_number) AS unique_returns
    FROM catalog_returns
    GROUP BY cr_item_sk
),
JoinWithItemInfo AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        COALESCE(rs.PriceRank, 0) AS PriceRank,
        COALESCE(ar.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(ar.avg_return_amount, 0) AS avg_return_amount,
        CASE 
            WHEN COALESCE(ar.total_return_quantity, 0) > 10 THEN 'High Return'
            WHEN COALESCE(ar.total_return_quantity, 0) BETWEEN 1 AND 10 THEN 'Moderate Return'
            ELSE 'Low Return'
        END AS ReturnCategory
    FROM item i
    LEFT JOIN RankedSales rs ON i.i_item_sk = rs.ws_item_sk AND rs.PriceRank = 1
    LEFT JOIN AggregatedReturns ar ON i.i_item_sk = ar.cr_item_sk
)
SELECT 
    w.w_warehouse_name,
    COUNT(DISTINCT j.i_item_id) AS unique_items,
    SUM(j.total_return_quantity) AS total_returns,
    AVG(j.avg_return_amount) AS average_return_amount,
    ARRAY_AGG(DISTINCT j.ReturnCategory) AS ReturnCategories,
    CASE 
        WHEN SUM(j.total_return_quantity) > 50 THEN 'Significant Returns'
        ELSE 'Manageable Returns'
    END AS ReturnImpact
FROM JoinWithItemInfo j
JOIN warehouse w ON j.PriceRank > 0
GROUP BY 
    w.w_warehouse_name
HAVING AVG(j.avg_return_amount) < (SELECT AVG(ws_sales_price) FROM web_sales)
ORDER BY 
    unique_items DESC, total_returns DESC
LIMIT 10;
