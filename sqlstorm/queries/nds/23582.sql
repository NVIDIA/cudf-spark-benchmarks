
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS sales_rank,
        SUM(ws_ext_sales_price) OVER (PARTITION BY ws_item_sk) AS total_sales_per_item
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL
),
FilteredReturns AS (
    SELECT 
        cr_item_sk,
        COUNT(*) AS total_returns,
        SUM(cr_return_amt_inc_tax) AS total_return_value,
        STRING_AGG(DISTINCT CAST(cr_reason_sk AS STRING), ', ') AS return_reasons
    FROM 
        catalog_returns
    GROUP BY 
        cr_item_sk
),
InventoryData AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory
    GROUP BY 
        inv_item_sk
)
SELECT 
    fo.ws_item_sk,
    fo.ws_order_number,
    fo.ws_sales_price,
    fo.total_sales_per_item,
    fr.total_returns,
    fr.total_return_value,
    CASE 
        WHEN fr.total_returns IS NULL THEN 'No Returns'
        ELSE fr.return_reasons
    END AS reasons
FROM 
    RankedSales fo
LEFT JOIN 
    FilteredReturns fr ON fo.ws_item_sk = fr.cr_item_sk
LEFT JOIN 
    InventoryData id ON fo.ws_item_sk = id.inv_item_sk
WHERE 
    (
        (fo.sales_rank = 1 AND fo.total_sales_per_item > (SELECT AVG(total_sales_per_item) FROM RankedSales))
        OR id.total_inventory IS NULL
    )
    AND (fo.total_sales_per_item > 100 OR fr.total_return_value IS NULL)
GROUP BY 
    fo.ws_item_sk, 
    fo.ws_order_number, 
    fo.ws_sales_price, 
    fo.total_sales_per_item, 
    fr.total_returns, 
    fr.total_return_value, 
    fr.return_reasons
ORDER BY 
    fo.ws_sales_price DESC
LIMIT 50;
