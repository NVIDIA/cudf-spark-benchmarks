
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), 
ReturnStatistics AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returned,
        COUNT(DISTINCT wr_order_number) AS return_count
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
SalesAndReturns AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_profit,
        COALESCE(rsr.total_returned, 0) AS total_returned,
        COALESCE(rsr.return_count, 0) AS return_count
    FROM 
        RankedSales rs
    LEFT JOIN 
        ReturnStatistics rsr ON rs.ws_item_sk = rsr.wr_item_sk
)
SELECT 
    s.ws_item_sk,
    s.total_quantity,
    s.total_profit,
    s.total_returned,
    s.return_count,
    CASE 
        WHEN s.total_profit > 10000 THEN 'High' 
        WHEN s.total_profit BETWEEN 5000 AND 10000 THEN 'Medium' 
        ELSE 'Low' 
    END AS profitability_category,
    ROUND(COALESCE(s.total_returned * 1.0 / NULLIF(s.total_quantity, 0), 0), 2) AS return_rate
FROM 
    SalesAndReturns s
WHERE 
    s.total_quantity > 100
ORDER BY 
    s.total_profit DESC
LIMIT 10;
