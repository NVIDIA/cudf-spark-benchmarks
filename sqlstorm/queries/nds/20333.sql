
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
TopSellingItems AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_sales_price,
        COALESCE(p.p_promo_id, 'No Promo') AS promo_id
    FROM 
        RankedSales rs
    LEFT JOIN 
        promotion p ON rs.ws_item_sk = p.p_item_sk AND rs.rn = 1
),
CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        cr_item_sk,
        SUM(cr_return_quantity) AS total_return_quantity
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk, cr_item_sk
),
ReturnStatistics AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        COALESCE(SUM(cr.total_return_quantity), 0) AS total_returned_items
    FROM 
        customer ci
    LEFT JOIN 
        CustomerReturns cr ON ci.c_customer_sk = cr.cr_returning_customer_sk
    GROUP BY 
        ci.c_customer_sk, ci.c_first_name, ci.c_last_name
)
SELECT 
    ts.ws_item_sk,
    ts.total_quantity,
    ts.total_sales_price,
    rs.c_first_name,
    rs.c_last_name,
    rs.total_returned_items
FROM 
    TopSellingItems ts
LEFT JOIN 
    ReturnStatistics rs ON ts.ws_item_sk = rs.total_returned_items
WHERE 
    ts.total_quantity > (SELECT AVG(total_quantity) FROM RankedSales)
    AND (ts.promo_id IS NULL OR ts.promo_id <> 'No Promo')
ORDER BY 
    ts.total_sales_price DESC
LIMIT 100;

