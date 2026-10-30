
WITH RankedOrders AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk = (SELECT MAX(ws2.ws_ship_date_sk) FROM web_sales ws2)
),
TopProfitOrders AS (
    SELECT 
        wo.ws_order_number,
        SUM(pr_total) AS total_profit
    FROM 
        (SELECT 
            ws.ws_order_number,
            CASE 
                WHEN ws.ws_net_profit IS NULL THEN 0 
                ELSE ws.ws_net_profit 
            END AS pr_total
        FROM 
            web_sales ws 
        WHERE 
            ws.ws_ship_mode_sk IN (SELECT sm_ship_mode_sk FROM ship_mode WHERE sm_type = 'AIR')) AS wo
    WHERE 
        wo.ws_order_number IS NOT NULL
    GROUP BY 
        wo.ws_order_number
),
CustomerReturns AS (
    SELECT 
        sr.sr_customer_sk,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_count,
        SUM(sr.sr_return_amt) AS total_return_amount
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_customer_sk
),
CustomerSpending AS (
    SELECT 
        c.c_customer_sk,
        SUM(COALESCE(ws.ws_net_paid, 0)) AS total_spending
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    c.c_customer_id,
    cs.total_spending,
    COALESCE(cr.return_count, 0) AS return_count,
    COALESCE(cr.total_return_amount, 0) AS total_returns,
    CASE 
        WHEN cs.total_spending IS NULL OR cs.total_spending = 0 THEN 'No Purchases'
        ELSE 'Active Customer'
    END AS customer_status
FROM 
    customer c
LEFT JOIN 
    CustomerSpending cs ON c.c_customer_sk = cs.c_customer_sk
LEFT JOIN 
    CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
WHERE 
    (cs.total_spending > 1000 OR cr.return_count > 5)
ORDER BY 
    total_spending DESC, return_count DESC
LIMIT 50;
