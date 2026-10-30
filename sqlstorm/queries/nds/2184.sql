
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS rank_order
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk 
                                FROM date_dim d 
                                WHERE d.d_year = 2023)
),
CustomerReturns AS (
    SELECT 
        sr.sr_item_sk,
        SUM(sr.sr_return_quantity) AS total_returns,
        COUNT(DISTINCT sr.sr_ticket_number) AS total_return_count
    FROM 
        store_returns sr 
    GROUP BY 
        sr.sr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(SUM(rs.ws_quantity), 0) AS total_quantity_sold,
    COALESCE(SUM(rs.ws_net_profit), 0) AS total_profit,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(cr.total_return_count, 0) AS total_return_count,
    COALESCE(SUM(rs.ws_net_profit), 0) - COALESCE(cr.total_returns, 0) AS net_gain_loss
FROM 
    item i 
LEFT JOIN 
    RankedSales rs ON i.i_item_sk = rs.ws_item_sk 
LEFT JOIN 
    CustomerReturns cr ON i.i_item_sk = cr.sr_item_sk
GROUP BY 
    i.i_item_id, i.i_item_desc, cr.total_returns, cr.total_return_count
HAVING 
    COALESCE(SUM(rs.ws_net_profit), 0) - COALESCE(cr.total_returns, 0) < 0 
ORDER BY 
    total_profit DESC, total_quantity_sold DESC;
