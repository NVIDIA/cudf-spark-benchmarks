
WITH customer_stats AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender, 
        cd.cd_marital_status,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_paid) AS total_spent,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
top_customers AS (
    SELECT 
        c.*, 
        RANK() OVER (ORDER BY total_spent DESC) AS rank
    FROM 
        customer_stats c
)
SELECT 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    c.cd_gender, 
    c.cd_marital_status, 
    c.total_quantity, 
    c.total_spent, 
    c.total_transactions
FROM 
    top_customers c
WHERE 
    c.rank <= 10
ORDER BY 
    c.total_spent DESC;
