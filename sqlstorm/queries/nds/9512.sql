WITH customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        hd.hd_income_band_sk,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON hd.hd_demo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        hd.hd_income_band_sk,
        hd.hd_dep_count,
        hd.hd_vehicle_count
),
age_distribution AS (
    SELECT 
        CASE 
            WHEN (EXTRACT(YEAR FROM cast('2002-10-01' as date)) - c_birth_year) < 20 THEN 'Under 20'
            WHEN (EXTRACT(YEAR FROM cast('2002-10-01' as date)) - c_birth_year) BETWEEN 20 AND 29 THEN '20-29'
            WHEN (EXTRACT(YEAR FROM cast('2002-10-01' as date)) - c_birth_year) BETWEEN 30 AND 39 THEN '30-39'
            WHEN (EXTRACT(YEAR FROM cast('2002-10-01' as date)) - c_birth_year) BETWEEN 40 AND 49 THEN '40-49'
            ELSE '50 and above'
        END AS age_group,
        COUNT(*) AS total_customers,
        SUM(total_orders) AS total_orders,
        SUM(total_spent) AS total_spent
    FROM 
        customer_data cd
    JOIN 
        customer c ON cd.c_customer_sk = c.c_customer_sk
    GROUP BY 
        age_group
)
SELECT 
    age_group,
    total_customers,
    total_orders,
    total_spent,
    ROUND(total_spent / NULLIF(total_orders, 0), 2) AS avg_spent_per_order
FROM 
    age_distribution
ORDER BY 
    CASE age_group
        WHEN 'Under 20' THEN 1
        WHEN '20-29' THEN 2
        WHEN '30-39' THEN 3
        WHEN '40-49' THEN 4
        ELSE 5
    END;