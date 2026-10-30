
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        COUNT(ws_order_number) AS order_count,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        ws_item_sk,
        total_sales
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 10
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
ReturnMetrics AS (
    SELECT 
        t.ws_item_sk,
        COALESCE(cr.total_returns, 0) AS return_count,
        COALESCE(cr.total_return_amt, 0) AS return_amount,
        CASE 
            WHEN cr.total_returns IS NULL THEN 'No Returns'
            WHEN cr.total_returns = 0 THEN 'Zero Returns'
            ELSE 'Returns exist'
        END AS return_status
    FROM 
        TopItems t
    LEFT JOIN 
        CustomerReturns cr ON t.ws_item_sk = cr.sr_item_sk
)
SELECT 
    it.i_item_desc,
    tm.return_count,
    tm.return_amount,
    tm.return_status,
    COUNT(DISTINCT w.ws_order_number) AS total_orders,
    SUM(CASE WHEN tm.return_count > 0 THEN w.ws_sales_price ELSE 0 END) AS net_sales_with_returns
FROM 
    ReturnMetrics tm
JOIN 
    item it ON tm.ws_item_sk = it.i_item_sk
LEFT JOIN 
    web_sales w ON tm.ws_item_sk = w.ws_item_sk
WHERE 
    tm.return_count < (SELECT AVG(return_count) FROM ReturnMetrics)
GROUP BY 
    it.i_item_desc, 
    tm.return_count, 
    tm.return_amount, 
    tm.return_status
HAVING 
    SUM(w.ws_sales_price) > 1000
ORDER BY 
    net_sales_with_returns DESC NULLS LAST;
