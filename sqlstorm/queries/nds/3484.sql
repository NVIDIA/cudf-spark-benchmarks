
WITH RankedSales AS (
    SELECT 
        ws_item_sk, 
        ws_quantity, 
        ws_sales_price, 
        ws_net_profit, 
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rn
    FROM 
        web_sales
),
TotalReturns AS (
    SELECT 
        sr_item_sk, 
        SUM(sr_return_quantity) AS total_return_qty, 
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
SalesComparison AS (
    SELECT 
        COALESCE(tb.ws_item_sk, tr.sr_item_sk) AS item_sk,
        COALESCE(tb.ws_net_profit, 0) AS total_net_profit,
        COALESCE(tr.total_return_qty, 0) AS total_return_quantity,
        COALESCE(tr.total_return_amt, 0) AS total_return_amount,
        CASE 
            WHEN COALESCE(tr.total_return_qty, 0) > 0 THEN 'Has Returns'
            ELSE 'No Returns'
        END AS return_status
    FROM 
        (
            SELECT 
                ws_item_sk, 
                SUM(ws_net_profit) AS ws_net_profit 
            FROM 
                web_sales 
            GROUP BY 
                ws_item_sk
        ) tb
    FULL OUTER JOIN 
        TotalReturns tr ON tb.ws_item_sk = tr.sr_item_sk
) 
SELECT 
    s.item_sk,
    s.total_net_profit,
    s.total_return_quantity,
    s.total_return_amount,
    s.return_status,
    RANK() OVER (ORDER BY s.total_net_profit DESC) AS profit_rank
FROM 
    SalesComparison s
WHERE 
    s.total_net_profit > 1000
ORDER BY 
    s.return_status DESC, s.total_net_profit DESC;
