
WITH customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_year,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_spent,
        AVG(ws.ws_sales_price) AS average_order_value
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_year
),
customer_income AS (
    SELECT 
        cd.cd_demo_sk,
        SUM(hd.hd_income_band_sk) AS total_income_bands
    FROM 
        customer_demographics cd
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    GROUP BY 
        cd.cd_demo_sk
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_orders,
        cs.total_spent,
        ci.total_income_bands,
        RANK() OVER (PARTITION BY cs.d_year ORDER BY cs.total_spent DESC) AS spending_rank,
        cs.d_year
    FROM 
        customer_stats cs
    LEFT JOIN 
        customer_income ci ON cs.c_customer_sk = ci.cd_demo_sk
    WHERE 
        cs.total_orders > 0
)
SELECT 
    t.c_first_name,
    t.c_last_name,
    t.total_orders,
    t.total_spent,
    t.total_income_bands,
    t.spending_rank,
    CASE 
        WHEN t.spending_rank <= 10 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_type
FROM 
    top_customers t
WHERE 
    t.d_year = 2023
ORDER BY 
    t.total_spent DESC;
