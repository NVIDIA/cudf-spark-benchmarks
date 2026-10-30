
WITH CustomerReturns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returned_quantity,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
),
StoreSales AS (
    SELECT 
        ss.ss_item_sk,
        SUM(ss.ss_sales_price) AS total_sales_price,
        SUM(ss.ss_quantity) AS total_sales_quantity
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_item_sk
),
SalesAndReturns AS (
    SELECT 
        s.ss_item_sk,
        COALESCE(c.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(s.total_sales_price, 0) AS total_sales_price,
        COALESCE(s.total_sales_quantity, 0) AS total_sales_quantity
    FROM 
        StoreSales s
    LEFT JOIN 
        CustomerReturns c ON s.ss_item_sk = c.cr_item_sk
)
SELECT 
    a.i_item_id,
    a.i_item_desc,
    COALESCE(s.total_returned_quantity, 0) AS total_returned_quantity,
    COALESCE(s.total_sales_price, 0) AS total_sales_price,
    COALESCE(s.total_sales_quantity, 0) AS total_sales_quantity,
    ROUND((COALESCE(s.total_returned_quantity, 0) * 100.0 / NULLIF(s.total_sales_quantity, 0)), 2) AS return_rate,
    ROUND((COALESCE(s.total_sales_price, 0) / NULLIF(s.total_sales_quantity, 0)), 2) AS avg_sales_price
FROM 
    item a
LEFT JOIN 
    SalesAndReturns s ON a.i_item_sk = s.ss_item_sk
GROUP BY 
    a.i_item_id,
    a.i_item_desc,
    s.total_returned_quantity,
    s.total_sales_price,
    s.total_sales_quantity
ORDER BY 
    return_rate DESC, avg_sales_price DESC
LIMIT 50;
