
WITH customer_stats AS (
    SELECT 
        c.c_customer_sk, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_spent,
        AVG(ws.ws_sales_price) AS avg_order_value,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_sales_price) DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
income_distribution AS (
    SELECT 
        hd.hd_income_band_sk, 
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        household_demographics hd
    JOIN 
        customer c ON hd.hd_demo_sk = c.c_current_hdemo_sk
    GROUP BY 
        hd.hd_income_band_sk
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cs.total_orders,
        cs.total_spent,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS spending_rank
    FROM 
        customer_stats cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
)
SELECT 
    tc.full_name,
    tc.total_orders,
    tc.total_spent,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    id.customer_count,
    CASE 
        WHEN tc.total_spent IS NULL THEN 'No Orders'
        WHEN tc.total_spent BETWEEN 0 AND 100 THEN 'Low Spend'
        WHEN tc.total_spent BETWEEN 100 AND 500 THEN 'Medium Spend'
        ELSE 'High Spend'
    END AS spending_category
FROM 
    top_customers tc
LEFT JOIN 
    income_band ib ON tc.total_orders = ib.ib_income_band_sk
LEFT JOIN 
    income_distribution id ON ib.ib_income_band_sk = id.hd_income_band_sk
WHERE 
    tc.spending_rank <= 10
ORDER BY 
    tc.total_spent DESC;
