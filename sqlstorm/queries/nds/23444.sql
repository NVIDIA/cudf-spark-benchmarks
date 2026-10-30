
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_sales_price,
        ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sales_price > 0
),
AggregatedReturns AS (
    SELECT 
        cr_item_sk,
        SUM(cr_return_quantity) AS total_returned,
        SUM(cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns
    GROUP BY 
        cr_item_sk
),
HighReturnItems AS (
    SELECT 
        ars.ws_item_sk,
        ars.ws_order_number,
        ars.ws_quantity,
        ars.ws_ext_sales_price,
        COALESCE(ar.total_returned, 0) AS total_returned,
        COALESCE(ar.total_return_amount, 0) AS total_return_amount
    FROM 
        RankedSales ars
    LEFT JOIN 
        AggregatedReturns ar ON ars.ws_item_sk = ar.cr_item_sk
    WHERE 
        ars.sales_rank = 1
)
SELECT 
    hi.ws_item_sk,
    hi.ws_order_number,
    hi.ws_quantity,
    hi.ws_ext_sales_price,
    CASE 
        WHEN hi.total_returned > 0 THEN 'High Return'
        ELSE 'Low Return'
    END AS return_status,
    (hi.ws_ext_sales_price - (hi.total_return_amount / NULLIF(hi.total_returned, 0) * hi.ws_quantity)) AS adjusted_net_sales
FROM 
    HighReturnItems hi
WHERE 
    (hi.ws_quantity IS NOT NULL AND hi.total_returned IS NOT NULL)
    OR hi.ws_quantity = 0
ORDER BY 
    adjusted_net_sales DESC, hi.ws_item_sk
LIMIT 100;
