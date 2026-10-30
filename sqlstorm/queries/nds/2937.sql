
WITH CustomerReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk IS NOT NULL 
    GROUP BY 
        sr_returned_date_sk, sr_item_sk
),
TopItems AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sold,
        SUM(ws_sales_price) AS total_revenue
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
    ORDER BY 
        total_revenue DESC
    LIMIT 10
),
ReturnStatistics AS (
    SELECT 
        ci.ws_item_sk,
        ci.total_sold,
        ci.total_revenue,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        CASE 
            WHEN ci.total_sold = 0 THEN 0
            ELSE (COALESCE(cr.total_returns, 0) * 1.0 / ci.total_sold)
        END AS return_rate
    FROM 
        TopItems ci
    LEFT JOIN 
        CustomerReturns cr ON ci.ws_item_sk = cr.sr_item_sk
)
SELECT 
    r.ws_item_sk,
    r.total_sold,
    r.total_revenue,
    r.total_returns,
    r.total_return_amount,
    r.return_rate,
    CASE 
        WHEN r.return_rate > 0.1 THEN 'High Return Rate'
        WHEN r.return_rate BETWEEN 0.05 AND 0.1 THEN 'Moderate Return Rate'
        ELSE 'Low Return Rate'
    END AS return_rate_category
FROM 
    ReturnStatistics r
WHERE 
    r.total_revenue > 1000
ORDER BY 
    r.return_rate DESC,
    r.total_revenue DESC;
