
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price) AS total_quantity
    FROM 
        web_sales ws
), 
HighPriceItems AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_sales_price,
        rs.total_quantity
    FROM 
        RankedSales rs
    WHERE 
        rs.price_rank = 1
),
CustomerReturns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returns
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
),
StoreReturns AS (
    SELECT 
        sr.sr_item_sk,
        SUM(sr.sr_return_quantity) AS total_store_returns
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_item_sk
),
ReturnStatistics AS (
    SELECT 
        hi.ws_item_sk,
        hi.ws_sales_price,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(sr.total_store_returns, 0) AS total_store_returns,
        (COALESCE(cr.total_returns, 0) + COALESCE(sr.total_store_returns, 0)) AS total_all_returns
    FROM 
        HighPriceItems hi
    LEFT JOIN 
        CustomerReturns cr ON hi.ws_item_sk = cr.cr_item_sk
    LEFT JOIN 
        StoreReturns sr ON hi.ws_item_sk = sr.sr_item_sk
)
SELECT 
    r.ws_item_sk,
    r.ws_sales_price,
    r.total_returns,
    r.total_store_returns,
    r.total_all_returns,
    CASE 
        WHEN r.total_all_returns > 0 THEN 'Returned'
        ELSE 'Not Returned'
    END AS return_status,
    CASE 
        WHEN r.total_all_returns > (SELECT AVG(total_all_returns) FROM ReturnStatistics) THEN 'Above Average Returns'
        ELSE 'Below Average Returns'
    END AS return_average_comparison
FROM 
    ReturnStatistics r
WHERE 
    r.ws_sales_price > 100
ORDER BY 
    r.total_all_returns DESC
LIMIT 10;
