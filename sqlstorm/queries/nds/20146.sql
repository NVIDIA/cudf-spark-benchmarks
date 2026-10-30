
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank,
        COUNT(*) OVER (PARTITION BY ws.ws_item_sk) AS total_sales
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk > (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022)
        AND ws.ws_quantity > 0
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned,
        COUNT(sr_ticket_number) AS return_count,
        COALESCE(SUM(sr_return_amt_inc_tax), 0) AS total_returned_amount
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
    HAVING 
        COUNT(sr_ticket_number) > 0
),
ProfitLoss AS (
    SELECT 
        r.ws_item_sk,
        r.ws_order_number,
        r.ws_net_profit,
        COALESCE(cr.total_returned, 0) AS total_returned_quantity,
        COALESCE(cr.total_returned_amount, 0) AS total_returned_amount,
        r.ws_net_profit - COALESCE(cr.total_returned_amount, 0) AS adjusted_profit
    FROM 
        RankedSales r
    LEFT JOIN 
        CustomerReturns cr ON r.ws_item_sk = cr.sr_item_sk
    WHERE 
        r.profit_rank = 1 AND r.total_sales >= 5
)
SELECT 
    p.i_item_desc,
    p.i_current_price,
    pl.ws_order_number,
    pl.adjusted_profit,
    CASE 
        WHEN pl.adjusted_profit IS NULL OR pl.adjusted_profit < 0 THEN 'Loss'
        WHEN pl.adjusted_profit = 0 THEN 'Break-even'
        ELSE 'Profit'
    END AS profit_status
FROM 
    ProfitLoss pl
JOIN 
    item p ON pl.ws_item_sk = p.i_item_sk
WHERE 
    pl.adjusted_profit IS NOT NULL
ORDER BY 
    pl.adjusted_profit DESC, p.i_item_desc
LIMIT 100;
