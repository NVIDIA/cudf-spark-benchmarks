WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS web_orders,
        COUNT(DISTINCT sr_ticket_number) AS store_returns,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ss.ss_net_profit) DESC) AS profit_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
TopCustomers AS (
    SELECT 
        * 
    FROM 
        CustomerStats 
    WHERE 
        profit_rank <= 10
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.total_net_profit,
    COALESCE(tc.web_orders, 0) AS web_orders,
    COALESCE(tc.store_returns, 0) AS store_returns,
    CASE 
        WHEN tc.total_net_profit IS NULL THEN 'No Profit'
        WHEN tc.total_net_profit > 1000 THEN 'High Profit'
        WHEN tc.total_net_profit BETWEEN 500 AND 1000 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM 
    TopCustomers tc
ORDER BY 
    tc.total_net_profit DESC;