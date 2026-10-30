
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_orders,
        cs.total_profit,
        cs.avg_purchase_estimate,
        RANK() OVER (ORDER BY cs.total_profit DESC) AS customer_rank
    FROM 
        CustomerStats cs
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    cs.total_orders,
    cs.total_profit,
    cs.avg_purchase_estimate
FROM 
    TopCustomers cs
JOIN 
    customer c ON cs.c_customer_sk = c.c_customer_sk
WHERE 
    cs.customer_rank <= 10
ORDER BY 
    cs.total_profit DESC;
