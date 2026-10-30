
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        cd.cd_gender
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990
        AND ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),

AggregateSales AS (
    SELECT 
        cd_gender,
        COUNT(*) AS customer_count,
        AVG(total_sales) AS avg_sales,
        MAX(total_sales) AS max_sales,
        MIN(total_sales) AS min_sales
    FROM 
        CustomerSales
    GROUP BY 
        cd_gender
)

SELECT 
    asales.cd_gender,
    asales.customer_count,
    asales.avg_sales,
    asales.max_sales,
    asales.min_sales,
    CAST(asales.avg_sales AS DECIMAL(10, 2)) / NULLIF(asales.customer_count, 0) AS sales_per_customer
FROM 
    AggregateSales asales
ORDER BY 
    sales_per_customer DESC;
