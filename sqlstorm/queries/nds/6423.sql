
WITH CustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_marital_status = 'M' 
        AND cd.cd_gender = 'F'
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        cd.cd_purchase_estimate, 
        cd.cd_credit_rating, 
        cd.cd_dep_count, 
        cd.cd_dep_employed_count, 
        cd.cd_dep_college_count
), 
SalesSummary AS (
    SELECT 
        md.d_year,
        SUM(total_sales) AS total_sales_amount,
        COUNT(DISTINCT c_customer_sk) AS unique_customers
    FROM 
        CustomerData cd
    JOIN 
        date_dim md ON cd.c_customer_sk = md.d_date_sk
    WHERE 
        md.d_year BETWEEN 2021 AND 2023
    GROUP BY 
        md.d_year
)
SELECT 
    ss.d_year,
    ss.total_sales_amount,
    ss.unique_customers,
    ss.total_sales_amount / NULLIF(ss.unique_customers, 0) AS avg_sales_per_customer
FROM 
    SalesSummary ss
ORDER BY 
    ss.d_year;
