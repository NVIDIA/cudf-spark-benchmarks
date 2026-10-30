
WITH RecursiveSales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank_profit
    FROM web_sales
    WHERE ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_item_sk
),
CombinedReturns AS (
    SELECT cr_item_sk, 
           SUM(cr_return_amount) AS total_returns
    FROM catalog_returns
    GROUP BY cr_item_sk
),
FinalMetrics AS (
    SELECT 
        i.i_item_id,
        COALESCE(rs.total_profit, 0) AS total_profit,
        COALESCE(crs.total_returns, 0) AS total_returns,
        CASE 
            WHEN COALESCE(rs.total_profit, 0) > 0 THEN 'Profitable'
            WHEN COALESCE(crs.total_returns, 0) > 0 THEN 'Return-heavy'
            ELSE 'Neutral'
        END AS performance_status
    FROM item i
    LEFT JOIN RecursiveSales rs ON i.i_item_sk = rs.ws_item_sk
    LEFT JOIN CombinedReturns crs ON i.i_item_sk = crs.cr_item_sk
),
FinalDashboard AS (
    SELECT 
        f.*,
        DENSE_RANK() OVER (ORDER BY f.total_profit DESC) AS profit_rank,
        CASE 
            WHEN f.total_profit IS NULL AND f.total_returns IS NULL THEN 'Unknown'
            ELSE 'Known'
        END AS data_state
    FROM FinalMetrics f
    WHERE (f.total_profit > 1000 OR f.total_returns > 500)
    ORDER BY f.total_profit DESC, f.total_returns ASC
)
SELECT 
    fd.i_item_id,
    fd.total_profit,
    fd.total_returns,
    fd.performance_status,
    fd.profit_rank,
    fd.data_state
FROM FinalDashboard fd
WHERE fd.performance_status != 'Neutral'
AND (fd.total_profit IS NOT NULL OR fd.total_returns IS NOT NULL)
ORDER BY fd.performance_status, fd.profit_rank DESC;
