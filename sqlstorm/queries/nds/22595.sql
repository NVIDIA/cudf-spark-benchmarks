
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_net_profit IS NOT NULL
),
ReturnStats AS (
    SELECT 
        cr.cr_item_sk,
        COUNT(DISTINCT cr.cr_order_number) AS return_count,
        SUM(cr.cr_return_amt_inc_tax) AS total_returns
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
),
TotalSales AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_profit) AS total_profit
    FROM 
        catalog_sales cs
    GROUP BY 
        cs.cs_item_sk
),
SalesWithReturns AS (
    SELECT 
        ts.cs_item_sk,
        ts.total_quantity,
        ts.total_profit,
        COALESCE(rs.return_count, 0) AS return_count,
        COALESCE(rs.total_returns, 0) AS total_returns,
        CASE 
            WHEN ts.total_profit > 0 THEN (COALESCE(rs.total_returns, 0) / ts.total_profit) * 100
            ELSE 0
        END AS return_percentage
    FROM 
        TotalSales ts
    LEFT JOIN 
        ReturnStats rs ON ts.cs_item_sk = rs.cr_item_sk
)

SELECT 
    sa.ws_order_number,
    sa.ws_item_sk,
    sa.ws_quantity AS quantity_sold,
    s.total_profit,
    s.return_count,
    s.total_returns,
    s.return_percentage,
    CASE 
        WHEN s.return_percentage > 0 THEN 'High Risk'
        ELSE 'Normal'
    END AS risk_level
FROM 
    RankedSales sa
JOIN 
    SalesWithReturns s ON sa.ws_item_sk = s.cs_item_sk
WHERE 
    sa.rn = 1
    AND s.total_profit > 500
    AND (s.return_percentage IS NULL OR s.return_percentage < 10)
ORDER BY 
    s.return_percentage DESC, s.total_profit DESC
LIMIT 100;
