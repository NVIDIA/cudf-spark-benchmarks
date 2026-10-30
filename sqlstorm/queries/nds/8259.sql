
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_ext_sales_price) AS total_sales, 
        COUNT(ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        rs.total_sales,
        rs.order_count
    FROM 
        RankedSales rs
    JOIN 
        customer c ON rs.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        rs.sales_rank <= 10
),
CustomerDemographics AS (
    SELECT 
        cu.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        TopCustomers cu
    JOIN 
        customer_demographics cd ON cu.c_customer_sk = cd.cd_demo_sk
),
SalesByDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(*) AS customer_count,
        SUM(tc.total_sales) AS total_sales
    FROM 
        CustomerDemographics cd
    JOIN 
        TopCustomers tc ON cd.c_customer_sk = tc.c_customer_sk
    GROUP BY 
        cd.cd_gender, 
        cd.cd_marital_status
)
SELECT 
    cd_gender,
    cd_marital_status,
    customer_count,
    total_sales,
    ROUND((total_sales / NULLIF(customer_count, 0)), 2) AS avg_sales_per_customer
FROM 
    SalesByDemographics
ORDER BY 
    total_sales DESC;
