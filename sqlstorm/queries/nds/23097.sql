WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_net_paid > 0
),
FilteredReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
    GROUP BY 
        sr_item_sk
),
ReturnRates AS (
    SELECT 
        rs.ws_item_sk,
        rs.rank,
        COALESCE(fr.total_returned, 0) AS total_returned,
        COALESCE(fr.total_return_amt, 0) AS total_return_amt,
        CASE 
            WHEN SUM(ws.ws_quantity) > 0 THEN 
                (COALESCE(fr.total_returned, 0) * 1.0 / SUM(ws.ws_quantity)) 
            ELSE 0 
        END AS return_rate
    FROM 
        RankedSales rs
    LEFT JOIN 
        web_sales ws ON rs.ws_item_sk = ws.ws_item_sk AND rs.ws_order_number = ws.ws_order_number
    LEFT JOIN 
        FilteredReturns fr ON fr.sr_item_sk = rs.ws_item_sk
    GROUP BY 
        rs.ws_item_sk, rs.rank, fr.total_returned, fr.total_return_amt
)
SELECT 
    r.ws_item_sk,
    r.return_rate,
    CASE 
        WHEN r.return_rate > 0.5 THEN 'High Return Rate'
        WHEN r.return_rate BETWEEN 0.2 AND 0.5 THEN 'Moderate Return Rate'
        ELSE 'Low Return Rate'
    END AS return_rate_category
FROM 
    ReturnRates r
WHERE 
    r.rank = 1
ORDER BY 
    r.return_rate DESC;