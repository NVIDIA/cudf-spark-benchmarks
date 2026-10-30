
WITH CustomerStats AS (
    SELECT 
        c.c_customer_id,
        COALESCE(cd.cd_gender, 'Unknown') AS gender,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_ship_date_sk) AS unique_ship_dates
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender
),
TopCustomers AS (
    SELECT 
        cs.c_customer_id,
        cs.gender,
        cs.total_orders,
        cs.total_profit,
        RANK() OVER (PARTITION BY cs.gender ORDER BY cs.total_profit DESC) AS profit_rank
    FROM 
        CustomerStats cs
),
ReturningCustomers AS (
    SELECT 
        c.c_customer_id,
        SUM(cr.cr_return_amount) AS total_returns
    FROM 
        customer c
    JOIN 
        catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    GROUP BY 
        c.c_customer_id
)
SELECT 
    tc.c_customer_id,
    tc.gender,
    tc.total_orders,
    tc.total_profit,
    COALESCE(rc.total_returns, 0) AS total_returns,
    CASE 
        WHEN tc.total_orders > 0 THEN ROUND((tc.total_profit - COALESCE(rc.total_returns, 0)) / tc.total_orders, 2)
        ELSE 0 
    END AS average_profit_per_order
FROM 
    TopCustomers tc
LEFT JOIN 
    ReturningCustomers rc ON tc.c_customer_id = rc.c_customer_id
WHERE 
    tc.profit_rank <= 10
ORDER BY 
    tc.gender, tc.total_profit DESC;
