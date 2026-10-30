
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
), TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.cd_credit_rating,
        cs.total_profit,
        cs.order_count,
        cs.avg_order_value,
        ROW_NUMBER() OVER (PARTITION BY cs.cd_gender ORDER BY cs.total_profit DESC) AS gender_rank
    FROM 
        CustomerSales cs
)
SELECT 
    tc.c_customer_sk,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.cd_credit_rating,
    tc.total_profit,
    tc.order_count,
    tc.avg_order_value
FROM 
    TopCustomers tc
WHERE 
    tc.gender_rank <= 10
ORDER BY 
    tc.cd_gender, tc.total_profit DESC;
