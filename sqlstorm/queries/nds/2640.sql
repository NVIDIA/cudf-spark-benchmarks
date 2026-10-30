
WITH customer_stats AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        AVG(ws.ws_quantity) AS avg_order_quantity,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS gender_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        cs.total_orders,
        cs.total_spent,
        cs.avg_order_quantity,
        cs.gender_rank
    FROM 
        customer_stats cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
    WHERE 
        cs.total_orders > 0
),
income_bracket AS (
    SELECT 
        hd.hd_demo_sk,
        ib.ib_income_band_sk,
        MIN(ib.ib_lower_bound) AS lower_bound,
        MAX(ib.ib_upper_bound) AS upper_bound
    FROM 
        household_demographics hd
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        hd.hd_demo_sk, ib.ib_income_band_sk
),
customer_summary AS (
    SELECT 
        tc.c_customer_id,
        COALESCE(ib.lower_bound, 0) AS lower_income_bound,
        COALESCE(ib.upper_bound, 100000) AS upper_income_bound,
        tc.total_orders,
        tc.total_spent,
        tc.avg_order_quantity
    FROM 
        top_customers tc
    LEFT JOIN 
        income_bracket ib ON tc.gender_rank = ib.hd_demo_sk
)
SELECT 
    cs.c_customer_id,
    cs.total_orders,
    cs.total_spent,
    cs.avg_order_quantity,
    CASE 
        WHEN cs.total_spent < cs.lower_income_bound THEN 'Low Income'
        WHEN cs.total_spent BETWEEN cs.lower_income_bound AND cs.upper_income_bound THEN 'Middle Income'
        ELSE 'High Income'
    END AS income_category
FROM 
    customer_summary cs
ORDER BY 
    cs.total_spent DESC
LIMIT 100;
