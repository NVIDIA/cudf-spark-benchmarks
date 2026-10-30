
WITH sales_summary AS (
    SELECT 
        d.d_year AS year,
        d.d_month_seq AS month,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2021 AND 2023
    GROUP BY 
        d.d_year, d.d_month_seq
),
customer_summary AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(cs.cs_sales_price * cs.cs_quantity) AS total_catalog_sales
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        cd.cd_gender
)
SELECT 
    ss.year, 
    ss.month, 
    ss.total_sales, 
    ss.total_orders, 
    ss.avg_sales_price, 
    cs.cd_gender, 
    cs.customer_count, 
    cs.total_catalog_sales
FROM 
    sales_summary ss
LEFT JOIN 
    customer_summary cs ON ss.year = 2022 AND ss.month = 1
ORDER BY 
    ss.year, 
    ss.month, 
    cs.cd_gender;
