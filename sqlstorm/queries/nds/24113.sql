
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rank_profit,
        CUME_DIST() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit) AS cum_dist_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON dd.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        dd.d_year = 2023
        AND (ws.ws_ship_date_sk IS NOT NULL OR ws.ws_net_profit IS NOT NULL)
),
AggregatedSales AS (
    SELECT 
        rs.ws_item_sk,
        COUNT(rs.ws_order_number) AS order_count,
        SUM(rs.ws_net_profit) AS total_profit,
        AVG(rs.ws_net_profit) AS avg_profit
    FROM 
        RankedSales rs
    WHERE 
        rs.rank_profit <= 5
    GROUP BY 
        rs.ws_item_sk
),
CustomerReturns AS (
    SELECT 
        cr.cr_item_sk,
        COUNT(cr.cr_return_quantity) AS total_returns,
        SUM(cr.cr_net_loss) AS total_loss
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
)
SELECT 
    i.i_item_id,
    COALESCE(a.order_count, 0) AS order_count,
    COALESCE(a.total_profit, 0.00) AS total_profit,
    COALESCE(a.avg_profit, 0.00) AS avg_profit,
    COALESCE(r.total_returns, 0) AS total_returns,
    COALESCE(r.total_loss, 0.00) AS total_loss,
    CASE 
        WHEN COALESCE(a.total_profit, 0) > 0 
        THEN (COALESCE(r.total_returns, 0) * 1.0 / COALESCE(a.order_count, 1)) 
        ELSE NULL 
    END AS return_rate
FROM 
    item i
LEFT JOIN 
    AggregatedSales a ON i.i_item_sk = a.ws_item_sk
LEFT JOIN 
    CustomerReturns r ON i.i_item_sk = r.cr_item_sk
WHERE 
    (a.avg_profit IS NOT NULL OR r.total_returns > 0)
    AND (i.i_current_price > 0 OR i.i_rec_end_date IS NULL)
ORDER BY 
    return_rate DESC NULLS LAST;
