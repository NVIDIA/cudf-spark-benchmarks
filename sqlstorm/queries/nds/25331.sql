WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(cd.cd_education_status, 'Unknown') AS education_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid) DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
top_spenders AS (
    SELECT 
        full_name,
        total_orders,
        total_spent,
        cd_gender,
        cd_marital_status,
        education_status
    FROM 
        ranked_customers
    WHERE 
        rank <= 10
)
SELECT 
    ts.full_name,
    ts.total_orders,
    ts.total_spent,
    ts.cd_gender,
    ts.cd_marital_status,
    ts.education_status,
    COUNT(DISTINCT ws.ws_order_number) AS total_web_orders
FROM 
    top_spenders ts
LEFT JOIN 
    web_sales ws ON ts.full_name = CONCAT(ws.ws_bill_customer_sk, ' ') 
WHERE 
    ts.total_spent > 1000
GROUP BY 
    ts.full_name, ts.total_orders, ts.total_spent, ts.cd_gender, ts.cd_marital_status, ts.education_status
ORDER BY 
    ts.total_spent DESC;