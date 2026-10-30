
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
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
        c.c_birth_year BETWEEN 1980 AND 2000
    GROUP BY 
        c.c_customer_id, 
        CONCAT(c.c_first_name, ' ', c.c_last_name), 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status
),
RankedSales AS (
    SELECT 
        c.c_customer_id AS customer_id,
        c.full_name,
        c.total_sales,
        c.cd_gender,
        c.cd_marital_status,
        c.cd_education_status,
        RANK() OVER (PARTITION BY c.cd_gender ORDER BY c.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales c
)
SELECT 
    r.full_name, 
    r.total_sales, 
    r.cd_gender, 
    r.cd_marital_status, 
    r.cd_education_status
FROM 
    RankedSales r
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.cd_gender, r.total_sales DESC;
