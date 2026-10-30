
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating, cd.cd_purchase_estimate
),
date_summary AS (
    SELECT 
        dd.d_year,
        COUNT(DISTINCT cs.cs_order_number) AS total_orders,
        SUM(cs.cs_net_paid_inc_tax) AS total_revenue
    FROM 
        date_dim dd
    LEFT JOIN 
        catalog_sales cs ON dd.d_date_sk = cs.cs_sold_date_sk
    GROUP BY 
        dd.d_year
),
ranked_customers AS (
    SELECT 
        cs.*,
        RANK() OVER (PARTITION BY cs.cd_gender ORDER BY cs.total_spent DESC) AS spending_rank
    FROM 
        customer_summary cs
)
SELECT 
    rc.full_name,
    rc.cd_gender,
    rc.cd_marital_status,
    rc.total_spent,
    ds.total_orders,
    ds.total_revenue,
    CASE 
        WHEN rc.cd_purchase_estimate IS NULL THEN 'Estimate not available'
        ELSE CAST(rc.cd_purchase_estimate AS STRING)
    END AS purchase_estimate,
    COALESCE(rc.spending_rank, 0) AS spending_rank
FROM 
    ranked_customers rc
JOIN 
    date_summary ds ON rc.cd_purchase_estimate BETWEEN 100 AND 500
WHERE 
    rc.cd_gender IS NOT NULL
    AND UPPER(rc.cd_credit_rating) IN ('EXCELLENT', 'GOOD')
ORDER BY 
    rc.cd_gender, rc.total_spent DESC
LIMIT 50;
