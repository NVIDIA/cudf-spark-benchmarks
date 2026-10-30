WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
HighPerformingItems AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_sales,
        CASE 
            WHEN rs.total_sales IS NULL THEN 'No Sales'
            WHEN rs.total_sales > 1000 THEN 'High Value Item'
            ELSE 'Standard Item'
        END AS item_category
    FROM 
        RankedSales rs 
    WHERE 
        rs.sales_rank <= 10
),
TotalReturns AS (
    SELECT
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
)
SELECT 
    hi.ws_item_sk,
    hi.total_sales,
    COALESCE(tr.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(tr.total_return_amount, 0) AS total_return_amount,
    hi.item_category,
    CASE 
        WHEN hi.total_sales IS NOT NULL AND (COALESCE(tr.total_return_amount, 0) > hi.total_sales) 
            THEN 'WARNING: High Return Rate'
        ELSE 'Return Rate Acceptable'
    END AS return_analysis
FROM 
    HighPerformingItems hi
LEFT JOIN 
    TotalReturns tr ON hi.ws_item_sk = tr.cr_item_sk
WHERE 
    hi.item_category = 'High Value Item'
ORDER BY 
    hi.total_sales DESC;