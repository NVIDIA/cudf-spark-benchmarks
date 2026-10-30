
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS RankProfit
    FROM 
        web_sales
    WHERE 
        ws_net_profit IS NOT NULL
),
TopSoldItems AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS TotalQuantity
    FROM 
        web_sales
    WHERE 
        ws_ship_date_sk IS NOT NULL
    GROUP BY 
        ws_item_sk
    HAVING 
        SUM(ws_quantity) > 100
),
FilteredReturns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS TotalReturns
    FROM 
        web_returns
    WHERE 
        wr_return_amt_inc_tax < 0 AND 
        wr_return_quantity IS NOT NULL
    GROUP BY 
        wr_item_sk
),
FinalBenchmark AS (
    SELECT 
        i.i_item_id,
        COALESCE(ts.TotalQuantity, 0) AS TotalSold,
        COALESCE(tr.TotalReturns, 0) AS TotalReturned,
        rs.RankProfit
    FROM 
        item i
    LEFT JOIN TopSoldItems ts ON i.i_item_sk = ts.ws_item_sk
    LEFT JOIN FilteredReturns tr ON i.i_item_sk = tr.wr_item_sk
    LEFT JOIN RankedSales rs ON i.i_item_sk = rs.ws_item_sk AND rs.RankProfit <= 10
)
SELECT 
    f.i_item_id,
    f.TotalSold,
    f.TotalReturned,
    CASE 
        WHEN f.TotalSold > 0 THEN 
            ROUND((f.TotalReturned / CAST(f.TotalSold AS decimal)) * 100, 2)
        ELSE 0 
    END AS ReturnRate,
    CASE 
        WHEN f.RankProfit IS NOT NULL THEN 'Top Performer' 
        ELSE 'Regular Item' 
    END AS ItemStatus
FROM 
    FinalBenchmark f
WHERE 
    f.TotalSold > 0 OR f.TotalReturned > 0
ORDER BY 
    ReturnRate DESC, TotalSold DESC;
