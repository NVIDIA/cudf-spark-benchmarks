
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value,
        ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY SUM(ws.ws_net_profit) DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_net_profit,
        cs.total_orders,
        cs.avg_order_value,
        cd.cd_gender
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    WHERE 
        cs.total_net_profit > (SELECT AVG(total_net_profit) FROM CustomerSales) 
        AND (cd.cd_marital_status = 'M' OR cd.cd_marital_status IS NULL) 
)
SELECT 
    tc.c_customer_sk,
    tc.total_net_profit,
    tc.total_orders,
    tc.avg_order_value,
    COALESCE(sm.sm_type, 'Unknown') AS shipping_method
FROM 
    TopCustomers tc
LEFT JOIN 
    ship_mode sm ON tc.total_orders % 2 = sm.sm_ship_mode_sk
WHERE 
    EXISTS (
        SELECT 1 
        FROM store_sales ss 
        WHERE ss.ss_customer_sk = tc.c_customer_sk 
        AND ss.ss_net_paid > 100
    )
ORDER BY 
    tc.total_net_profit DESC
LIMIT 10;
