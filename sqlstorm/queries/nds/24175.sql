
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales AS ws
    WHERE 
        ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.ws_item_sk, ws.ws_order_number
),
TotalReturns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returns
    FROM 
        catalog_returns AS cr
    WHERE 
        cr.cr_returned_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        cr.cr_item_sk
)
SELECT 
    i.i_item_id,
    COALESCE(rs.total_quantity, 0) AS sold_quantity,
    COALESCE(rs.total_net_profit, 0) AS net_profit,
    COALESCE(tr.total_returns, 0) AS returns,
    CASE 
        WHEN COALESCE(tr.total_returns, 0) > 0 THEN
            ROUND((COALESCE(rs.total_net_profit, 0) / NULLIF(tr.total_returns, 0)), 2)
        ELSE 
            NULL 
    END AS profit_per_return
FROM 
    item AS i
LEFT JOIN 
    RankedSales AS rs ON i.i_item_sk = rs.ws_item_sk AND rs.profit_rank = 1
LEFT JOIN 
    TotalReturns AS tr ON i.i_item_sk = tr.cr_item_sk
WHERE 
    i.i_current_price IS NOT NULL 
    AND (i.i_item_desc LIKE '%special%' OR i.i_item_desc IS NULL)
ORDER BY 
    sold_quantity DESC, net_profit DESC;
