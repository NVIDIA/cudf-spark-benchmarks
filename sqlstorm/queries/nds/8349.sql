
WITH customer_sales_summary AS (
    SELECT 
        c.c_customer_id AS customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 2000
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
top_customers AS (
    SELECT 
        customer_id,
        cd_gender,
        cd_marital_status,
        total_sales,
        total_orders,
        RANK() OVER (PARTITION BY cd_gender ORDER BY total_sales DESC) AS sales_rank
    FROM 
        customer_sales_summary
)
SELECT 
    customer_id,
    cd_gender,
    cd_marital_status,
    total_sales,
    total_orders
FROM 
    top_customers
WHERE 
    sales_rank <= 5
ORDER BY 
    cd_gender, total_sales DESC;
