
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns 
    GROUP BY 
        sr_item_sk
),
SalesAndReturns AS (
    SELECT 
        r.ws_item_sk,
        r.total_sales,
        COALESCE(c.total_returns, 0) AS total_returns,
        r.total_sales - COALESCE(c.total_returns, 0) AS net_sales
    FROM 
        RankedSales r
    LEFT JOIN 
        CustomerReturns c ON r.ws_item_sk = c.sr_item_sk
    WHERE 
        r.sales_rank = 1
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    s.total_sales,
    s.total_returns,
    s.net_sales,
    CASE 
        WHEN s.net_sales < 0 THEN 'Loss'
        WHEN s.net_sales > 0 AND s.total_returns > 0 THEN 'Profit with Returns'
        WHEN s.net_sales > 0 AND s.total_returns = 0 THEN 'Profit'
        ELSE 'No Sales'
    END AS sales_status
FROM 
    SalesAndReturns s
JOIN 
    item i ON s.ws_item_sk = i.i_item_sk
WHERE 
    i.i_current_price > 50
    AND (s.net_sales IS NOT NULL OR s.total_returns > 0)
ORDER BY 
    s.net_sales DESC
LIMIT 10;
