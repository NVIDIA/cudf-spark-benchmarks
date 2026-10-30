
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        d.d_year
    FROM 
        customer c 
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2019 AND 2023
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, d.d_year
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_quantity,
        cs.total_sales,
        ROW_NUMBER() OVER (PARTITION BY cs.d_year ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
)
SELECT 
    cs.d_year,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.total_quantity
FROM 
    TopCustomers tc
JOIN 
    CustomerSales cs ON tc.c_customer_sk = cs.c_customer_sk
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    cs.d_year, tc.total_sales DESC;
