
WITH customer_data AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
customer_ranking AS (
    SELECT 
        *,
        DENSE_RANK() OVER (PARTITION BY cd_gender, cd_marital_status ORDER BY total_spent DESC) AS spending_rank
    FROM 
        customer_data
)
SELECT 
    cr.c_customer_id,
    cr.c_first_name,
    cr.c_last_name,
    cr.cd_gender,
    cr.cd_marital_status,
    cr.cd_education_status,
    cr.total_quantity,
    cr.total_spent,
    cr.spending_rank
FROM 
    customer_ranking cr
WHERE 
    cr.spending_rank <= 5
ORDER BY 
    cr.cd_gender, cr.cd_marital_status, cr.spending_rank;
