
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_purchases,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY COUNT(DISTINCT ss.ss_ticket_number) DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        cd.cd_marital_status = 'M' OR cd.cd_marital_status IS NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
top_customers AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        cd_gender,
        gender_rank
    FROM 
        ranked_customers
    WHERE 
        gender_rank <= 10
),
sales_summary AS (
    SELECT 
        SUM(ss.ss_net_paid) AS total_spent,
        COUNT(ss.ss_ticket_number) AS total_sales,
        ss.ss_item_sk
    FROM 
        store_sales ss
    JOIN 
        top_customers tc ON ss.ss_customer_sk = tc.c_customer_sk
    GROUP BY 
        ss.ss_item_sk
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(ss.total_spent, 0) AS total_spent,
    ss.total_sales
FROM 
    top_customers tc
FULL OUTER JOIN 
    sales_summary ss ON tc.c_customer_sk = ss.ss_item_sk
ORDER BY 
    total_spent DESC NULLS LAST;
