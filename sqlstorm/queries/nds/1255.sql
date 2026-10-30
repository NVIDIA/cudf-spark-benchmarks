
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20000101 AND 20231231
),
TopSales AS (
    SELECT 
        rs.ws_item_sk, 
        SUM(rs.ws_net_profit) AS total_net_profit
    FROM 
        RankedSales rs
    WHERE 
        rs.rn <= 5
    GROUP BY 
        rs.ws_item_sk
),
CustomerReturns AS (
    SELECT 
        cr.cr_item_sk,
        COUNT(cr.cr_order_number) AS return_count,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns cr
    WHERE 
        cr.cr_returned_date_sk BETWEEN 20000101 AND 20231231
    GROUP BY 
        cr.cr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(ts.total_net_profit, 0) AS total_net_profit,
    COALESCE(cr.return_count, 0) AS return_count,
    COALESCE(cr.total_return_amount, 0) AS total_return_amount
FROM 
    item i
LEFT JOIN 
    TopSales ts ON i.i_item_sk = ts.ws_item_sk
LEFT JOIN 
    CustomerReturns cr ON i.i_item_sk = cr.cr_item_sk
WHERE 
    (COALESCE(ts.total_net_profit, 0) > 1000 OR cr.return_count > 0)
ORDER BY 
    total_net_profit DESC, return_count DESC;
