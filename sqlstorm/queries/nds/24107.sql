
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2450010 AND 2450610
    GROUP BY 
        ws_item_sk
),
CustomerReturns AS (
    SELECT 
        cr_item_sk,
        COUNT(DISTINCT cr_order_number) AS return_count,
        SUM(cr_return_amount) AS total_return_amount,
        CASE 
            WHEN SUM(cr_return_amount) IS NULL THEN 'Unknown'
            ELSE 'Known'
        END AS return_status
    FROM 
        catalog_returns
    GROUP BY 
        cr_item_sk
),
SalesWithReturns AS (
    SELECT 
        r.ws_item_sk,
        r.total_quantity,
        COALESCE(c.return_count, 0) AS return_count,
        COALESCE(c.total_return_amount, 0.00) AS total_return_amount,
        ROUND((total_quantity / NULLIF((total_quantity + COALESCE(c.total_return_amount, 0.00)), 0)) * 100, 2) AS effective_sales_percentage
    FROM 
        RankedSales r
    LEFT JOIN 
        CustomerReturns c ON r.ws_item_sk = c.cr_item_sk
)
SELECT 
    s.ws_item_sk,
    s.total_quantity,
    s.return_count,
    s.total_return_amount,
    s.effective_sales_percentage
FROM 
    SalesWithReturns s
WHERE 
    s.effective_sales_percentage > (
        SELECT 
            AVG(effective_sales_percentage)
        FROM 
            SalesWithReturns
    )
ORDER BY 
    s.total_quantity DESC
LIMIT 10 OFFSET 0;
