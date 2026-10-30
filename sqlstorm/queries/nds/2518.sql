WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2451545 AND 2451910 
    GROUP BY 
        ws.ws_item_sk, ws.ws_order_number
),
SalesReturns AS (
    SELECT 
        sr.sr_item_sk,
        COUNT(sr.sr_ticket_number) AS total_returns,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_product_name,
    COALESCE(rs.total_quantity, 0) AS total_quantity_sold,
    COALESCE(rs.total_net_profit, 0) AS total_net_profit_sold,
    COALESCE(rtr.total_returns, 0) AS total_returns,
    COALESCE(rtr.total_return_amount, 0) AS total_return_amount,
    (COALESCE(rs.total_net_profit, 0) - COALESCE(rtr.total_return_amount, 0)) AS net_profit_after_returns
FROM 
    item i
LEFT JOIN 
    RankedSales rs ON i.i_item_sk = rs.ws_item_sk
LEFT JOIN 
    SalesReturns rtr ON i.i_item_sk = rtr.sr_item_sk
WHERE 
    (i.i_current_price > 50.00 OR i.i_brand = 'BrandX') AND
    (rs.rank = 1 OR rs.rank IS NULL)
ORDER BY 
    net_profit_after_returns DESC
LIMIT 10;