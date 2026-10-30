
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) as rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2450000 AND 2450600
),
TopItems AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_net_profit) AS total_net_profit
    FROM 
        RankedSales rs
    WHERE 
        rs.rank <= 5
    GROUP BY 
        rs.ws_item_sk
),
CustomerReturns AS (
    SELECT 
        cr.cr_item_sk,
        COUNT(cr.cr_order_number) AS return_count,
        SUM(cr.cr_net_loss) AS total_net_loss
    FROM 
        catalog_returns cr
    WHERE 
        EXISTS (
            SELECT 1 
            FROM TopItems ti
            WHERE cr.cr_item_sk = ti.ws_item_sk
        )
    GROUP BY 
        cr.cr_item_sk
),
SalesReturns AS (
    SELECT 
        ti.ws_item_sk,
        ti.total_net_profit,
        coalesce(cr.return_count, 0) AS total_returns,
        coalesce(cr.total_net_loss, 0) AS total_loss
    FROM 
        TopItems ti
    LEFT JOIN 
        CustomerReturns cr ON ti.ws_item_sk = cr.cr_item_sk
)
SELECT 
    s.ws_item_sk,
    s.total_net_profit,
    s.total_returns,
    s.total_loss,
    CASE 
        WHEN s.total_returns > 0 THEN (s.total_loss / s.total_returns)
        ELSE NULL 
    END AS avg_loss_per_return
FROM 
    SalesReturns s
WHERE 
    s.total_net_profit > 1000
ORDER BY 
    s.total_net_profit DESC
LIMIT 10;
