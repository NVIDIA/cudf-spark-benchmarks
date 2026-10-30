
WITH customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
        SUM(ws.ws_sales_price) AS total_web_spent,
        AVG(ws.ws_sales_price) AS avg_web_order_value
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_web_orders,
        cs.total_web_spent,
        RANK() OVER (ORDER BY cs.total_web_spent DESC) AS rank
    FROM 
        customer_stats cs
)
SELECT 
    tc.rank,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_web_orders,
    tc.total_web_spent
FROM 
    top_customers tc
WHERE 
    tc.rank <= 10
ORDER BY 
    tc.total_web_spent DESC;
