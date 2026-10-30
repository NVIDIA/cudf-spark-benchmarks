
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 13000 AND 13030
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_quantity,
        cs.total_spent,
        cs.order_count
    FROM 
        customer_sales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.total_spent > (SELECT AVG(total_spent) FROM customer_sales)
)
SELECT 
    hv.c_customer_sk,
    hv.c_first_name,
    hv.c_last_name,
    hv.total_quantity,
    hv.total_spent,
    hv.order_count,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status
FROM 
    high_value_customers hv
JOIN 
    customer_demographics cd ON hv.c_customer_sk = cd.cd_demo_sk
ORDER BY 
    hv.total_spent DESC
LIMIT 10;
