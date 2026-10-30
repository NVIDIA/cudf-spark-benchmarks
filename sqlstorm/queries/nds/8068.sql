
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        sr_returned_date_sk,
        sr_return_time_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt_inc_tax) AS total_return_amt_inc_tax,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_quantity) DESC) AS rank
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk, sr_returned_date_sk, sr_return_time_sk
),
ItemSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sales_quantity,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY 
        ws_item_sk
)
SELECT 
    i.i_item_id,
    COALESCE(r.total_return_quantity, 0) AS total_return_qty,
    COALESCE(r.total_return_amt_inc_tax, 0) AS total_return_amt,
    COALESCE(s.total_sales_quantity, 0) AS total_sales_qty,
    COALESCE(s.total_net_profit, 0) AS total_net_profit,
    i.i_current_price,
    (COALESCE(s.total_net_profit, 0) / NULLIF(COALESCE(s.total_sales_quantity, 0), 0)) AS avg_net_profit_per_item
FROM 
    item i
LEFT JOIN 
    RankedReturns r ON i.i_item_sk = r.sr_item_sk AND r.rank = 1
LEFT JOIN 
    ItemSales s ON i.i_item_sk = s.ws_item_sk
WHERE 
    i.i_current_price > 0
ORDER BY 
    total_return_amt DESC, avg_net_profit_per_item DESC
LIMIT 100;
