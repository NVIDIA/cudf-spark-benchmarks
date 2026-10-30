
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ss.ss_quantity) AS total_items_purchased,
        SUM(ss.ss_net_paid) AS total_spent,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
HighSpenders AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_items_purchased,
        cs.total_spent,
        cs.total_transactions,
        DENSE_RANK() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM 
        CustomerStats AS cs
    WHERE 
        cs.total_spent > 0
)
SELECT 
    hs.c_customer_sk,
    hs.c_first_name,
    hs.c_last_name,
    hs.total_items_purchased,
    hs.total_spent,
    hs.total_transactions,
    CASE 
        WHEN hs.rank <= 10 THEN 'Top 10 High Spender'
        WHEN hs.rank <= 100 THEN 'Top 100 High Spender'
        ELSE 'Regular Customer'
    END AS customer_segment
FROM 
    HighSpenders AS hs
WHERE 
    hs.rank <= 100 
ORDER BY 
    hs.total_spent DESC;
