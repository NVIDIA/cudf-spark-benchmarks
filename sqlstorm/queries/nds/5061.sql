
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(COALESCE(ss.ss_net_profit, 0) + COALESCE(ws.ws_net_profit, 0) + COALESCE(cs.cs_net_profit, 0)) AS total_net_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_purchases,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_purchases,
        DENSE_RANK() OVER (ORDER BY SUM(COALESCE(ss.ss_net_profit, 0) + COALESCE(ws.ws_net_profit, 0) + COALESCE(cs.cs_net_profit, 0)) DESC) AS net_profit_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_net_profit,
        cs.net_profit_rank,
        ROW_NUMBER() OVER (PARTITION BY cs.net_profit_rank ORDER BY cs.total_net_profit DESC) AS customer_rank
    FROM 
        CustomerStats cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.net_profit_rank <= 10
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_net_profit,
    tc.net_profit_rank
FROM 
    TopCustomers tc
WHERE 
    tc.customer_rank <= 5
ORDER BY 
    tc.net_profit_rank, tc.total_net_profit DESC;
