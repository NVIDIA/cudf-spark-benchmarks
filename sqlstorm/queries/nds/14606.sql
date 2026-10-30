
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
    GROUP BY 
        c.c_customer_sk
),
customer_demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer_demographics cd
)
SELECT 
    cs.c_customer_sk,
    cs.total_sales,
    cs.total_orders,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status
FROM 
    customer_sales cs
JOIN 
    customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
WHERE 
    cs.total_sales > 1000
ORDER BY 
    cs.total_sales DESC
LIMIT 100;
