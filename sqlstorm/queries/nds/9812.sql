
WITH CustomerSales AS (
    SELECT 
        cs_bill_customer_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        COUNT(DISTINCT cs_order_number) AS order_count
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk BETWEEN 
        (SELECT d_date_sk FROM date_dim WHERE d_year = 2022 AND d_month_seq = 12 LIMIT 1)
        AND 
        (SELECT d_date_sk FROM date_dim WHERE d_year = 2022 AND d_month_seq = 12 LIMIT 1 OFFSET 1)
    GROUP BY 
        cs_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        cs.total_sales,
        cs.order_count,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cs.total_sales > (SELECT AVG(total_sales) FROM CustomerSales)
)
SELECT 
    tc.c_customer_id,
    tc.total_sales,
    tc.order_count,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.cd_education_status
FROM 
    TopCustomers tc
ORDER BY 
    tc.total_sales DESC
LIMIT 10;
