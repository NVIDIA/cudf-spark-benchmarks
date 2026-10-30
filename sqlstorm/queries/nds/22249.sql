
WITH SalesSummary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    INNER JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk 
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_item_sk
), 
ReturnSummary AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returns
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
), 
JoinedSales AS (
    SELECT 
        ss.ws_item_sk,
        COALESCE(ss.total_quantity, 0) AS total_quantity,
        COALESCE(ss.total_profit, 0) AS total_profit,
        COALESCE(rs.total_returns, 0) AS total_returns,
        (COALESCE(ss.total_profit, 0) - COALESCE(rs.total_returns, 0)) AS net_profit_adjusted
    FROM 
        SalesSummary ss
    LEFT JOIN 
        ReturnSummary rs ON ss.ws_item_sk = rs.wr_item_sk
)
SELECT 
    j.ws_item_sk,
    j.total_quantity,
    j.total_profit,
    j.total_returns,
    CASE 
        WHEN j.net_profit_adjusted BETWEEN 100 AND 1000 THEN 'Medium Profit'
        WHEN j.net_profit_adjusted < 100 THEN 'Low Profit'
        ELSE 'High Profit'
    END AS profit_category,
    CASE 
        WHEN EXISTS (SELECT 1 FROM item i WHERE i.i_item_sk = j.ws_item_sk AND i.i_current_price > 20) THEN 'High Value Item'
        ELSE 'Standard Value Item'
    END AS item_value_category
FROM 
    JoinedSales j
WHERE 
    j.total_quantity > 5 
    AND j.total_profit IS NOT NULL
    AND (j.total_returns < 5 OR j.total_returns IS NULL)
ORDER BY 
    j.net_profit_adjusted DESC
LIMIT 100;
