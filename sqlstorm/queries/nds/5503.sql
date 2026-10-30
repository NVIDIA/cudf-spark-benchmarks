
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ss.ss_sales_price) AS total_spent,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        COUNT(DISTINCT sr.sr_ticket_number) AS total_returns
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_email_address, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_email_address,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.cd_education_status,
        cs.total_spent,
        cs.total_transactions,
        cs.total_returns
    FROM 
        CustomerStats cs
    WHERE 
        cs.total_spent > (SELECT AVG(total_spent) FROM CustomerStats)
)
SELECT 
    hvc.c_email_address,
    hvc.cd_gender,
    hvc.cd_marital_status,
    hvc.cd_education_status,
    hvc.total_spent,
    hvc.total_transactions,
    hvc.total_returns,
    CASE 
        WHEN hvc.total_transactions = 0 THEN 'Inactive'
        WHEN hvc.total_returns > 2 THEN 'Potential Churn'
        ELSE 'Active'
    END AS customer_status
FROM 
    HighValueCustomers hvc
ORDER BY 
    hvc.total_spent DESC
LIMIT 100;
