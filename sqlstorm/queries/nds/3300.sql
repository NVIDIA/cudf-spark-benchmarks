WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT max(d_date_sk) - 30 FROM date_dim) 
    GROUP BY 
        ws.ws_item_sk, ws.ws_order_number
), 
MonthlyReturns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returns
    FROM 
        catalog_returns cr
    WHERE 
        cr.cr_returned_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2001) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2001)
    GROUP BY 
        cr.cr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(RS.total_quantity, 0) AS total_sold,
    COALESCE(RS.total_profit, 0) AS total_profit,
    COALESCE(MR.total_returns, 0) AS total_returns,
    COALESCE(RS.total_profit - COALESCE(MR.total_returns, 0), 0) AS net_profit_after_returns
FROM 
    item i
LEFT JOIN 
    RankedSales RS ON i.i_item_sk = RS.ws_item_sk AND RS.rank_profit <= 5
LEFT JOIN 
    MonthlyReturns MR ON i.i_item_sk = MR.cr_item_sk
WHERE 
    i.i_rec_start_date <= cast('2002-10-01' as date) AND (i.i_rec_end_date IS NULL OR i.i_rec_end_date >= cast('2002-10-01' as date))
ORDER BY 
    net_profit_after_returns DESC;