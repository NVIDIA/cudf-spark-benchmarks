
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        MAX(ws.ws_sold_date_sk) AS last_purchase_date
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 2000
    GROUP BY 
        c.c_customer_sk
),
demographic_analysis AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        AVG(cs.total_sales) AS average_sales,
        AVG(cs.order_count) AS average_orders,
        COUNT(cs.c_customer_sk) AS customer_count
    FROM 
        customer_sales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
sales_performance AS (
    SELECT 
        da.cd_gender,
        da.cd_marital_status,
        da.average_sales,
        da.average_orders,
        da.customer_count,
        ROW_NUMBER() OVER (PARTITION BY da.cd_gender ORDER BY da.average_sales DESC) AS sales_rank
    FROM 
        demographic_analysis da
)
SELECT 
    sp.cd_gender,
    sp.cd_marital_status,
    sp.average_sales,
    sp.average_orders,
    sp.customer_count
FROM 
    sales_performance sp
WHERE 
    sp.sales_rank <= 5
ORDER BY 
    sp.cd_gender, sp.average_sales DESC;
