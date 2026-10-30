WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_paid DESC) AS rn
    FROM
        web_sales ws
    WHERE 
        ws.ws_net_paid > (SELECT AVG(ws_net_paid) FROM web_sales)
),
TopReturns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returned
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
),
SalesWithReturns AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_net_paid,
        COALESCE(tr.total_returned, 0) AS total_returned
    FROM 
        RankedSales rs
    LEFT JOIN 
        TopReturns tr ON rs.ws_item_sk = tr.cr_item_sk
    WHERE 
        rs.rn = 1
),
SalesStatistics AS (
    SELECT 
        swr.ws_item_sk,
        swr.total_returned,
        swr.ws_net_paid,
        CASE 
            WHEN swr.ws_net_paid > 100 THEN 'High'
            WHEN swr.ws_net_paid BETWEEN 50 AND 100 THEN 'Medium'
            ELSE 'Low'
        END AS revenue_category,
        CASE 
            WHEN swr.total_returned > 10 THEN 'High Returns'
            ELSE 'Acceptable Returns'
        END AS return_category
    FROM 
        SalesWithReturns swr
)
SELECT 
    ss.ws_item_sk,
    ss.ws_net_paid,
    ss.total_returned,
    ss.revenue_category,
    ss.return_category,
    cast('2002-10-01' as date) AS performance_date
FROM 
    SalesStatistics ss
WHERE 
    (ss.return_category = 'High Returns' AND ss.revenue_category = 'High')
    OR (ss.return_category = 'Acceptable Returns' AND ss.revenue_category = 'Low')
ORDER BY 
    ss.ws_item_sk;