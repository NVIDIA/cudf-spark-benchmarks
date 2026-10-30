
WITH CustomerSummary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ss.ss_net_paid_inc_tax) AS total_spent,
        COUNT(ss.ss_ticket_number) AS purchase_count,
        AVG(ss.ss_net_profit) AS avg_profit_per_purchase
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
TopCustomers AS (
    SELECT 
        c.*, 
        RANK() OVER (PARTITION BY c.cd_gender ORDER BY c.total_spent DESC) AS rank_within_gender
    FROM 
        CustomerSummary c
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.total_spent,
    tc.purchase_count,
    tc.avg_profit_per_purchase,
    CASE 
        WHEN tc.rank_within_gender <= 10 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_category
FROM 
    TopCustomers tc
WHERE 
    tc.rank_within_gender <= 10 OR tc.total_spent IS NULL
ORDER BY 
    tc.cd_gender, tc.total_spent DESC;
