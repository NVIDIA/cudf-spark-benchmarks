
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        CAST(d.d_date AS DATE) AS sales_date
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2022
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, d.d_date
), average_sales AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        cd_education_status,
        AVG(total_sales) AS avg_sales,
        AVG(total_quantity_sold) AS avg_quantity
    FROM 
        sales_summary
    GROUP BY 
        cd_gender, cd_marital_status, cd_education_status
)

SELECT 
    avg_sales.cd_gender,
    avg_sales.cd_marital_status,
    avg_sales.cd_education_status,
    avg_sales.avg_sales,
    avg_sales.avg_quantity,
    COUNT(ss.c_customer_id) AS customer_count
FROM 
    average_sales avg_sales
JOIN 
    sales_summary ss ON avg_sales.cd_gender = ss.cd_gender 
                      AND avg_sales.cd_marital_status = ss.cd_marital_status 
                      AND avg_sales.cd_education_status = ss.cd_education_status
GROUP BY 
    avg_sales.cd_gender, avg_sales.cd_marital_status, avg_sales.cd_education_status, avg_sales.avg_sales, avg_sales.avg_quantity
ORDER BY 
    avg_sales.avg_sales DESC;
