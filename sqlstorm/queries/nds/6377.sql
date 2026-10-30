WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(DISTINCT ws.ws_ship_date_sk) AS unique_ship_dates
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2001
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
age_distribution AS (
    SELECT 
        CASE 
            WHEN (EXTRACT(YEAR FROM cast('2002-10-01' as date)) - c.c_birth_year) < 20 THEN 'Under 20'
            WHEN (EXTRACT(YEAR FROM cast('2002-10-01' as date)) - c.c_birth_year) BETWEEN 20 AND 29 THEN '20-29'
            WHEN (EXTRACT(YEAR FROM cast('2002-10-01' as date)) - c.c_birth_year) BETWEEN 30 AND 39 THEN '30-39'
            WHEN (EXTRACT(YEAR FROM cast('2002-10-01' as date)) - c.c_birth_year) BETWEEN 40 AND 49 THEN '40-49'
            ELSE '50 and above'
        END AS age_group,
        COUNT(*) AS customer_count,
        SUM(ss.total_spent) AS total_metric_spent
    FROM 
        sales_summary ss
    JOIN 
        customer c ON ss.c_customer_id = c.c_customer_id
    GROUP BY 
        CASE 
            WHEN (EXTRACT(YEAR FROM cast('2002-10-01' as date)) - c.c_birth_year) < 20 THEN 'Under 20'
            WHEN (EXTRACT(YEAR FROM cast('2002-10-01' as date)) - c.c_birth_year) BETWEEN 20 AND 29 THEN '20-29'
            WHEN (EXTRACT(YEAR FROM cast('2002-10-01' as date)) - c.c_birth_year) BETWEEN 30 AND 39 THEN '30-39'
            WHEN (EXTRACT(YEAR FROM cast('2002-10-01' as date)) - c.c_birth_year) BETWEEN 40 AND 49 THEN '40-49'
            ELSE '50 and above'
        END
)
SELECT 
    ad.age_group,
    ad.customer_count,
    ad.total_metric_spent,
    SUM(ad.total_metric_spent) OVER () AS grand_total_spent,
    (ad.total_metric_spent / NULLIF(SUM(ad.total_metric_spent) OVER (), 0)) * 100 AS percentage_of_total
FROM 
    age_distribution ad
ORDER BY 
    ad.age_group;