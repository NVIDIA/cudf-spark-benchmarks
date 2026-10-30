
WITH sales_data AS (
    SELECT 
        d.d_date AS sale_date,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        c.c_birth_year,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT c.c_customer_id) AS customer_count
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        d.d_date, c.c_birth_year, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
avg_sales AS (
    SELECT 
        sale_date,
        AVG(total_sales) AS avg_sales_per_day,
        AVG(total_quantity) AS avg_quantity_per_day,
        c_birth_year AS birth_year,
        cd_gender AS gender,
        cd_marital_status AS marital_status,
        cd_education_status AS education_status
    FROM 
        sales_data
    GROUP BY 
        sale_date, c_birth_year, cd_gender, cd_marital_status, cd_education_status
),
ranked_sales AS (
    SELECT 
        sale_date,
        avg_sales_per_day,
        avg_quantity_per_day,
        birth_year,
        gender,
        marital_status,
        education_status,
        RANK() OVER (PARTITION BY birth_year, gender ORDER BY avg_sales_per_day DESC) AS sales_rank
    FROM 
        avg_sales
)
SELECT 
    sale_date,
    avg_sales_per_day,
    avg_quantity_per_day,
    birth_year,
    gender,
    marital_status,
    education_status,
    sales_rank
FROM 
    ranked_sales
WHERE 
    sales_rank <= 10
ORDER BY 
    birth_year, gender, avg_sales_per_day DESC;
