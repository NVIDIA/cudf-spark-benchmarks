
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        d.d_year AS sales_year,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        c.c_customer_id, d.d_year, cd.cd_gender, cd.cd_marital_status
), average_sales AS (
    SELECT 
        sales_year,
        cd_gender,
        cd_marital_status,
        AVG(total_sales) AS avg_total_sales,
        AVG(order_count) AS avg_order_count
    FROM 
        customer_sales
    GROUP BY 
        sales_year, cd_gender, cd_marital_status
)
SELECT 
    sales_year,
    cd_gender,
    cd_marital_status,
    avg_total_sales,
    avg_order_count
FROM 
    average_sales
ORDER BY 
    sales_year DESC, cd_gender, cd_marital_status;
