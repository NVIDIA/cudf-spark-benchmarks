
WITH RankedSales AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
),
CustomerReturns AS (
    SELECT 
        wr.wr_returned_date_sk,
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amt
    FROM 
        web_returns wr
    WHERE 
        wr.wr_returned_date_sk IS NOT NULL
    GROUP BY 
        wr.wr_returned_date_sk, wr.wr_item_sk
),
ProfitLoss AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        COALESCE(rs.ws_net_profit, 0) AS total_net_profit,
        COALESCE(cr.total_return_amt, 0) AS total_return_value,
        (COALESCE(rs.ws_net_profit, 0) - COALESCE(cr.total_return_amt, 0)) AS net_profit_loss
    FROM 
        item
    LEFT JOIN 
        RankedSales rs ON item.i_item_sk = rs.ws_item_sk
    LEFT JOIN 
        CustomerReturns cr ON item.i_item_sk = cr.wr_item_sk
)
SELECT 
    p.i_item_id,
    p.i_item_desc,
    p.total_net_profit,
    p.total_return_value,
    p.net_profit_loss,
    CASE
        WHEN p.net_profit_loss > 0 THEN 'Profitable'
        WHEN p.net_profit_loss < 0 THEN 'Loss'
        ELSE 'Break Even'
    END AS profitability_status
FROM 
    ProfitLoss p
WHERE 
    p.total_net_profit > 1000
ORDER BY 
    p.net_profit_loss DESC;
