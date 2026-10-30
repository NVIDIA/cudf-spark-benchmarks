
WITH  SalesInfo AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_sold_date_sk ORDER BY SUM(ws_net_profit) DESC) AS rn
    FROM web_sales
    GROUP BY ws_sold_date_sk
),
CustomerReturns AS (
    SELECT 
        cr.return_grid_customer_id,
        SUM(COALESCE(cr_return_amount, 0)) AS total_return_amount
    FROM (
        SELECT 
            wr_returning_customer_sk AS return_grid_customer_id,
            wr_return_amt AS cr_return_amount
        FROM web_returns
        UNION ALL
        SELECT 
            sr_customer_sk AS return_grid_customer_id,
            sr_return_amt AS cr_return_amount
        FROM store_returns
    ) AS cr
    GROUP BY cr.return_grid_customer_id
),
SalesAnalysis AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(ci.total_profit, 0) AS total_profit,
        COALESCE(cr.total_return_amount, 0) AS total_return
    FROM customer c
    LEFT JOIN SalesInfo ci ON ci.ws_sold_date_sk = c.c_first_sales_date_sk
    LEFT JOIN CustomerReturns cr ON cr.return_grid_customer_id = c.c_customer_sk
)
SELECT 
    sa.c_customer_sk,
    sa.total_profit,
    sa.total_return,
    sa.total_profit - sa.total_return AS net_profit,
    CASE 
        WHEN sa.total_profit > 100000 THEN 'High Value'
        WHEN sa.total_profit BETWEEN 50000 AND 100000 THEN 'Moderate Value'
        ELSE 'Low Value' 
    END AS customer_value_segment
FROM SalesAnalysis sa
WHERE sa.total_profit > 50000
AND sa.total_return IS NOT NULL
ORDER BY net_profit DESC
LIMIT 100;
