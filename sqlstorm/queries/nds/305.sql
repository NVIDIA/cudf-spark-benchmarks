
WITH CustomerStats AS (
    SELECT 
        c.c_customer_id, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM 
        customer c
    INNER JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
TopCustomers AS (
    SELECT 
        cs.c_customer_id,
        cs.total_profit,
        cs.order_count,
        cs.avg_order_value,
        DENSE_RANK() OVER (ORDER BY cs.total_profit DESC) AS rank
    FROM 
        CustomerStats cs
)
SELECT 
    tc.c_customer_id,
    tc.total_profit,
    tc.order_count,
    tc.avg_order_value,
    (SELECT COUNT(DISTINCT ws_bill_customer_sk)
     FROM web_sales 
     WHERE ws_net_profit > 500) AS high_profit_customers,
    CASE 
        WHEN tc.order_count > 5 THEN 'Frequent Shopper'
        WHEN tc.order_count BETWEEN 1 AND 5 THEN 'Occasional Shopper'
        ELSE 'No Purchase'
    END AS customer_type
FROM 
    TopCustomers tc
WHERE 
    tc.rank <= 10
ORDER BY 
    tc.total_profit DESC;
