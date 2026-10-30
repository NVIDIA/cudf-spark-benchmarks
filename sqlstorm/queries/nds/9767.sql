
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023) 
        AND (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
SalesSummary AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        cd_education_status,
        AVG(total_sales) AS avg_sales,
        MAX(total_sales) AS max_sales,
        MIN(total_sales) AS min_sales,
        SUM(order_count) AS total_orders
    FROM 
        CustomerSales
    GROUP BY 
        cd_gender, cd_marital_status, cd_education_status
)
SELECT 
    ss.cd_gender,
    ss.cd_marital_status,
    ss.cd_education_status,
    ss.avg_sales,
    ss.max_sales,
    ss.min_sales,
    ss.total_orders,
    RANK() OVER (ORDER BY ss.avg_sales DESC) AS sales_rank
FROM 
    SalesSummary ss
WHERE 
    ss.total_orders > 0
ORDER BY 
    ss.avg_sales DESC
LIMIT 10;
