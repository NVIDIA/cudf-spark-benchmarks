
WITH CustomerPerformance AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS avg_net_paid,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_profit) DESC) AS rn
    FROM 
        customer c 
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
TopCustomers AS (
    SELECT 
        *,
        CASE WHEN total_orders > 10 THEN 'High Value' ELSE 'Low Value' END AS customer_value
    FROM 
        CustomerPerformance
    WHERE 
        total_net_profit IS NOT NULL
),
RecentRefunds AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_amt) AS total_refunds,
        COUNT(wr_order_number) AS total_refund_orders
    FROM 
        web_returns
    WHERE 
        wr_returned_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        wr_returning_customer_sk
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.total_net_profit,
    tc.avg_net_paid,
    rc.total_refunds,
    rc.total_refund_orders,
    CASE 
        WHEN rc.total_refunds IS NULL THEN 'No Refunds'
        WHEN rc.total_refunds > tc.total_net_profit THEN 'Profitable Refunds'
        ELSE 'Standard Refunds'
    END AS refund_strategy,
    CASE 
        WHEN tc.total_net_profit IS NOT NULL AND tc.avg_net_paid > 100 THEN 'VIP Customer'
        ELSE 'Regular Customer'
    END AS customer_status
FROM 
    TopCustomers tc
LEFT JOIN 
    RecentRefunds rc ON tc.c_customer_sk = rc.wr_returning_customer_sk
WHERE 
    tc.rn <= 10
ORDER BY 
    tc.total_net_profit DESC NULLS LAST;

