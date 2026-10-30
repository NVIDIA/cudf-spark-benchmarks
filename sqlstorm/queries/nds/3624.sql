
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_month = 6
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_spent,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM 
        customer_sales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.total_spent > 1000
)
SELECT 
    hvc.c_customer_sk,
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_spent,
    hc.cd_marital_status,
    COALESCE(ihb.ib_lower_bound, 0) AS lower_bound,
    COALESCE(ihb.ib_upper_bound, 0) AS upper_bound
FROM 
    high_value_customers hvc
LEFT JOIN 
    customer_demographics hc ON hvc.c_customer_sk = hc.cd_demo_sk
LEFT JOIN 
    household_demographics hhd ON hvc.c_customer_sk = hhd.hd_demo_sk
LEFT JOIN 
    income_band ihb ON hhd.hd_income_band_sk = ihb.ib_income_band_sk
WHERE 
    hvc.rank <= 10
ORDER BY 
    hvc.total_spent DESC;

