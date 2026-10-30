
WITH  SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rn
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.ws_item_sk
),
CustomerReturns AS (
    SELECT 
        cr.cr_item_sk,
        COUNT(cr.cr_return_quantity) AS total_returns,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    GROUP BY cr.cr_item_sk
)
SELECT 
    sd.ws_item_sk,
    COALESCE(sd.total_net_profit, 0) AS total_net_profit,
    COALESCE(sd.total_orders, 0) AS total_orders,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(cr.total_return_amount, 0) AS total_return_amount,
    CASE 
        WHEN COALESCE(sd.total_net_profit, 0) > 0 THEN 
            (COALESCE(cr.total_return_amount, 0) / COALESCE(sd.total_net_profit, 0)) * 100 
        ELSE 0 
    END AS return_rate_percentage
FROM SalesData sd
FULL OUTER JOIN CustomerReturns cr ON sd.ws_item_sk = cr.cr_item_sk
WHERE sd.rn = 1 OR cr.cr_item_sk IS NOT NULL
ORDER BY total_net_profit DESC, total_returns DESC;
