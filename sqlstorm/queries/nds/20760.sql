
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
        AND ws.ws_sold_date_sk <= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        ws.ws_item_sk
),

QualifiedReturns AS (
    SELECT 
        sr.sr_item_sk,
        SUM(sr.sr_return_quantity) AS total_return_quantity,
        SUM(sr.sr_return_amt) AS total_return_amt
    FROM 
        store_returns sr
    WHERE 
        sr.sr_returned_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        sr.sr_item_sk
),

FinalMetrics AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_net_profit,
        COALESCE(qr.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(qr.total_return_amt, 0) AS total_return_amt,
        (rs.total_net_profit - COALESCE(qr.total_return_amt, 0)) AS net_profit_after_returns
    FROM 
        RankedSales rs
    LEFT JOIN 
        QualifiedReturns qr ON rs.ws_item_sk = qr.sr_item_sk
)

SELECT 
    fm.ws_item_sk,
    fm.total_quantity,
    fm.total_net_profit,
    fm.total_return_quantity,
    fm.total_return_amt,
    fm.net_profit_after_returns,
    CASE 
        WHEN fm.net_profit_after_returns > 0 THEN 'Profitable'
        WHEN fm.net_profit_after_returns = 0 THEN 'Break-even'
        ELSE 'Loss'
    END AS profitability_status
FROM 
    FinalMetrics fm
WHERE 
    fm.total_quantity > (
        SELECT AVG(total_quantity) FROM FinalMetrics
    )
ORDER BY 
    fm.net_profit_after_returns DESC
LIMIT 10;
