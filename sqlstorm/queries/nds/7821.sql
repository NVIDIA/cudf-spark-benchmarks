WITH customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_birth_year,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_purchases,
        SUM(ss.ss_net_paid_inc_tax) AS total_spent,
        AVG(ss.ss_net_profit) AS avg_profit_per_purchase
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY 
        c.c_customer_sk, c.c_birth_year, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
age_distribution AS (
    SELECT 
        CASE 
            WHEN EXTRACT(YEAR FROM cast('2002-10-01' as date)) - c.c_birth_year BETWEEN 0 AND 25 THEN '0-25'
            WHEN EXTRACT(YEAR FROM cast('2002-10-01' as date)) - c.c_birth_year BETWEEN 26 AND 40 THEN '26-40'
            WHEN EXTRACT(YEAR FROM cast('2002-10-01' as date)) - c.c_birth_year BETWEEN 41 AND 55 THEN '41-55'
            ELSE '56+' 
        END AS age_group,
        COUNT(1) AS customer_count,
        SUM(total_spent) AS total_revenue,
        AVG(total_spent) AS avg_revenue_per_customer
    FROM 
        customer_stats c
    GROUP BY 
        age_group
)
SELECT 
    ad.age_group,
    ad.customer_count,
    ad.total_revenue,
    ad.avg_revenue_per_customer,
    cd.cd_gender,
    cd.cd_marital_status
FROM 
    age_distribution ad
JOIN 
    customer_stats cs ON cs.c_customer_sk IN (SELECT DISTINCT c.c_customer_sk FROM customer c)
JOIN 
    customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
ORDER BY 
    ad.age_group ASC, ad.total_revenue DESC;