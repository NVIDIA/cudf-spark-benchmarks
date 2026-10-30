
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_ship_date_sk,
        ws.ws_net_paid,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_paid DESC) AS rank_net_paid
    FROM web_sales ws
    WHERE ws.ws_ship_date_sk BETWEEN 20220101 AND 20221231
),
TopSales AS (
    SELECT 
        rs.ws_order_number,
        rs.ws_item_sk,
        rs.ws_net_paid
    FROM RankedSales rs
    WHERE rs.rank_net_paid <= 5
),
TotalReturns AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amt
    FROM web_returns wr
    WHERE wr.wr_returned_date_sk IS NOT NULL
    GROUP BY wr.wr_item_sk
),
SalesAndReturns AS (
    SELECT 
        ts.ws_order_number,
        ts.ws_item_sk,
        COALESCE(tr.total_return_qty, 0) AS total_return_qty,
        COALESCE(tr.total_return_amt, 0) AS total_return_amt,
        ts.ws_net_paid - COALESCE(tr.total_return_amt, 0) AS net_after_returns
    FROM TopSales ts
    LEFT JOIN TotalReturns tr ON ts.ws_item_sk = tr.wr_item_sk
)
SELECT 
    item.i_item_id,
    SUM(sar.net_after_returns) AS final_net,
    COUNT(DISTINCT sar.ws_order_number) AS unique_orders,
    COUNT(DISTINCT sar.total_return_qty) AS unique_returns,
    CASE 
        WHEN SUM(sar.net_after_returns) IS NULL THEN 'No Sales' 
        ELSE CASE 
            WHEN SUM(sar.net_after_returns) > 0 THEN 'Profit'
            WHEN SUM(sar.net_after_returns) < 0 THEN 'Loss'
            ELSE 'Break-even' 
        END 
    END AS financial_status
FROM SalesAndReturns sar
JOIN item ON sar.ws_item_sk = item.i_item_sk
GROUP BY item.i_item_id
HAVING 
    CASE 
        WHEN SUM(sar.net_after_returns) IS NULL THEN 'No Sales' 
        ELSE CASE 
            WHEN SUM(sar.net_after_returns) > 0 THEN 'Profit'
            WHEN SUM(sar.net_after_returns) < 0 THEN 'Loss'
            ELSE 'Break-even' 
        END 
    END != 'No Sales'
ORDER BY final_net DESC, unique_orders DESC
LIMIT 10;
