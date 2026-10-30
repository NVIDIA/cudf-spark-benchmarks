
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_purchases,
        SUM(ss.ss_net_paid) AS total_spent,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ss.ss_net_paid) DESC) AS gender_rank
    FROM 
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        cd.cd_gender IS NOT NULL
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
TopCustomers AS (
    SELECT 
        rc.c_customer_id,
        rc.c_first_name,
        rc.c_last_name,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.cd_education_status,
        rc.total_purchases,
        rc.total_spent
    FROM 
        RankedCustomers rc
    WHERE 
        rc.gender_rank <= 5
)
SELECT 
    tc.cd_gender,
    COUNT(tc.c_customer_id) AS count_top_customers,
    AVG(tc.total_spent) AS avg_spent,
    SUM(tc.total_purchases) AS total_purchases_by_gender
FROM 
    TopCustomers tc
GROUP BY 
    tc.cd_gender
ORDER BY 
    tc.cd_gender;
