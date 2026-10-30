
WITH customer_age_data AS (
    SELECT 
        c.c_customer_sk,
        YEAR(CAST('2002-10-01' AS DATE)) - c.c_birth_year AS customer_age,
        cd.cd_gender,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_purchases,
        SUM(ss.ss_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_birth_year, cd.cd_gender
),
average_spent AS (
    SELECT 
        CASE 
            WHEN customer_age < 25 THEN 'Under 25'
            WHEN customer_age BETWEEN 25 AND 34 THEN '25-34'
            WHEN customer_age BETWEEN 35 AND 44 THEN '35-44'
            WHEN customer_age BETWEEN 45 AND 54 THEN '45-54'
            WHEN customer_age BETWEEN 55 AND 64 THEN '55-64'
            ELSE '65 and over'
        END AS age_group,
        AVG(total_spent) AS avg_spent,
        COUNT(c_customer_sk) AS customer_count
    FROM 
        customer_age_data
    GROUP BY 
        age_group
)
SELECT 
    age_group,
    avg_spent,
    customer_count,
    RANK() OVER (ORDER BY avg_spent DESC) AS rank
FROM 
    average_spent
WHERE 
    customer_count > 10
ORDER BY 
    rank;
