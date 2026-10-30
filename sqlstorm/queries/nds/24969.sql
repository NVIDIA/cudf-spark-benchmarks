
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rnk
    FROM web_sales
    GROUP BY ws_item_sk
),
AdjustedReturns AS (
    SELECT 
        cr_item_sk,
        SUM(cr_return_quantity) AS total_returns,
        SUM(cr_return_amount) AS total_return_amount,
        COALESCE(NULLIF(SUM(cr_fee), 0), 1) AS adjusted_fee
    FROM catalog_returns
    GROUP BY cr_item_sk
),
InventoryStatus AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_quantity_on_hand,
        CASE 
            WHEN SUM(inv_quantity_on_hand) < 0 THEN 'Negative'
            WHEN SUM(inv_quantity_on_hand) = 0 THEN 'Zero'
            ELSE 'Positive'
        END AS inventory_status
    FROM inventory
    GROUP BY inv_item_sk
)
SELECT 
    i.i_item_id,
    COALESCE(r.total_sales, 0) AS total_sales,
    COALESCE(ar.total_returns, 0) AS total_returns,
    COALESCE(i_status.total_quantity_on_hand, 0) AS total_quantity_on_hand,
    CASE 
        WHEN COALESCE(ar.total_return_amount, 0) > 1000 THEN 'High Return'
        WHEN COALESCE(ar.total_return_amount, 0) BETWEEN 500 AND 1000 THEN 'Moderate Return'
        ELSE 'Low Return'
    END AS return_category,
    ROW_NUMBER() OVER (ORDER BY COALESCE(r.total_sales, 0) DESC) AS sales_rank
FROM item i
LEFT JOIN RankedSales r ON i.i_item_sk = r.ws_item_sk AND r.rnk = 1
LEFT JOIN AdjustedReturns ar ON i.i_item_sk = ar.cr_item_sk
FULL OUTER JOIN InventoryStatus i_status ON i.i_item_sk = i_status.inv_item_sk
WHERE i.i_current_price IS NOT NULL
ORDER BY sales_rank,
    return_category DESC,
    total_quantity_on_hand DESC
LIMIT 10;
