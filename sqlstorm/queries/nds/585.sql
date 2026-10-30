WITH customer_stats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid) AS total_spent,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_net_paid) DESC) AS spending_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.order_count,
        cs.total_spent
    FROM 
        customer_stats cs
    WHERE 
        cs.spending_rank <= 10
),
high_income_customers AS (
    SELECT 
        cd.cd_demo_sk, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        ib.ib_income_band_sk
    FROM 
        customer_demographics cd
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE 
        ib.ib_upper_bound > 80000  
),
customer_details AS (
    SELECT 
        tc.c_customer_sk,
        tc.order_count,
        tc.total_spent,
        hi.cd_gender,
        hi.cd_marital_status,
        hi.ib_income_band_sk,
        ROW_NUMBER() OVER (PARTITION BY hi.cd_gender ORDER BY tc.total_spent DESC) AS gender_rank
    FROM 
        top_customers tc
    JOIN 
        high_income_customers hi ON tc.c_customer_sk = hi.cd_demo_sk
)
SELECT 
    cd.c_customer_sk,
    cd.order_count,
    cd.total_spent,
    cd.cd_gender,
    cd.cd_marital_status,
    CASE 
        WHEN cd.gender_rank <= 5 THEN 'Top 5 by Income'
        ELSE 'Below Top 5 by Income'
    END AS income_group,
    COALESCE(wa.w_warehouse_name, 'No Warehouse Assigned') AS warehouse_name
FROM 
    customer_details cd
LEFT JOIN 
    warehouse wa ON cd.c_customer_sk = wa.w_warehouse_sk
WHERE 
    (cd.order_count > 5 OR cd.total_spent > 1000)
ORDER BY 
    cd.total_spent DESC
LIMIT 100;