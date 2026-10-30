
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY 
        c.c_customer_sk
    HAVING 
        SUM(ws.ws_net_paid) > 1000
),
sales_summary AS (
    SELECT 
        cd.cd_gender,
        COUNT(cs.c_customer_sk) AS customer_count,
        SUM(cs.total_sales) AS total_sales,
        AVG(cs.avg_sales_price) AS avg_sales_price
    FROM 
        customer_sales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
)
SELECT 
    ss.cd_gender,
    ss.customer_count,
    ss.total_sales,
    ss.avg_sales_price,
    DENSE_RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
FROM 
    sales_summary ss
ORDER BY 
    ss.total_sales DESC
LIMIT 5;
