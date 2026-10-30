
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (
        SELECT d.d_date_sk
        FROM date_dim d
        WHERE d.d_year = 2023 AND d.d_moy IN (1, 2, 3)
    )
),
TopSales AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_quantity) AS total_quantity,
        AVG(rs.ws_net_profit) AS avg_net_profit
    FROM RankedSales rs
    WHERE rs.profit_rank <= 10
    GROUP BY rs.ws_item_sk
),
DetailedReturns AS (
    SELECT 
        sr.sr_item_sk,
        SUM(sr.sr_return_quantity) AS total_returned,
        SUM(sr.sr_return_amt_inc_tax) AS total_returned_amt
    FROM store_returns sr
    WHERE sr.sr_returned_date_sk IN (
        SELECT d.d_date_sk
        FROM date_dim d
        WHERE d.d_year = 2023
    )
    GROUP BY sr.sr_item_sk
),
FinalBenchmark AS (
    SELECT 
        ts.ws_item_sk,
        COALESCE(ts.total_quantity, 0) AS total_quantity,
        COALESCE(ts.avg_net_profit, 0) AS avg_net_profit,
        COALESCE(dr.total_returned, 0) AS total_returned,
        COALESCE(dr.total_returned_amt, 0) AS total_returned_amt,
        CASE 
            WHEN COALESCE(dr.total_returned, 0) = 0 THEN 'No returns'
            WHEN COALESCE(ts.total_quantity, 0) = 0 THEN 'No sales'
            ELSE CAST((1.0 * COALESCE(dr.total_returned, 0) / COALESCE(ts.total_quantity, 1)) * 100 AS DECIMAL(5,2)) || '%' 
        END AS return_percentage
    FROM TopSales ts
    LEFT JOIN DetailedReturns dr ON ts.ws_item_sk = dr.sr_item_sk
)

SELECT 
    f.ws_item_sk,
    f.total_quantity,
    f.avg_net_profit,
    f.total_returned,
    f.total_returned_amt,
    f.return_percentage
FROM FinalBenchmark f
ORDER BY f.avg_net_profit DESC, f.total_quantity ASC
LIMIT 20;
