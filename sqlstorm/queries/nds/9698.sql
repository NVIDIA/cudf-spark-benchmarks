
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c 
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
sales_by_gender AS (
    SELECT 
        cd.cd_gender,
        SUM(cs.total_sales) AS total_sales_by_gender,
        SUM(cs.order_count) AS orders_by_gender
    FROM 
        customer_sales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
),
average_sales AS (
    SELECT 
        AVG(total_sales_by_gender) AS avg_sales,
        AVG(orders_by_gender) AS avg_orders
    FROM 
        sales_by_gender
),
max_sales AS (
    SELECT 
        cd.cd_gender,
        MAX(cs.total_sales) AS max_sales_value
    FROM 
        customer_sales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
)
SELECT 
    sbg.cd_gender,
    sbg.total_sales_by_gender,
    sbg.orders_by_gender,
    avg.avg_sales,
    avg.avg_orders,
    ms.max_sales_value
FROM 
    sales_by_gender sbg
CROSS JOIN 
    average_sales avg
JOIN 
    max_sales ms ON sbg.cd_gender = ms.cd_gender
ORDER BY 
    sbg.total_sales_by_gender DESC;
