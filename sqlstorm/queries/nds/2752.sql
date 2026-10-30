
WITH RankedReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_return_quantity,
        COUNT(cr_order_number) AS total_returns,
        DENSE_RANK() OVER (PARTITION BY cr_returning_customer_sk ORDER BY SUM(cr_return_quantity) DESC) AS return_rank
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
),
CustomerReturns AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        r.total_return_quantity,
        r.total_returns,
        r.return_rank
    FROM 
        customer c
    JOIN 
        RankedReturns r ON c.c_customer_sk = r.cr_returning_customer_sk
    WHERE 
        r.return_rank <= 5
),
TopNShipping AS (
    SELECT 
        sm.sm_ship_mode_id,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS profitability_rank
    FROM 
        web_sales ws
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        sm.sm_ship_mode_id
)
SELECT 
    cr.c_customer_id,
    cr.c_first_name,
    cr.c_last_name,
    ts.sm_ship_mode_id,
    ts.total_orders,
    ts.total_profit,
    (CR.total_return_quantity * 1.0 / NULLIF(ts.total_orders, 0)) AS return_rate,
    CASE 
        WHEN ts.total_profit > 1000 THEN 'High Profit'
        WHEN ts.total_profit BETWEEN 500 AND 1000 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM 
    CustomerReturns cr
JOIN 
    TopNShipping ts ON cr.total_returns > (SELECT AVG(total_returns) FROM CustomerReturns)
WHERE 
    cr.return_rank <= 5 
ORDER BY 
    ts.total_profit DESC, 
    cr.c_last_name;
