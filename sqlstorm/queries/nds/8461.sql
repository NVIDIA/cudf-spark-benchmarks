WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk BETWEEN 2450000 AND 2450600 
    GROUP BY 
        ws_bill_customer_sk
),

HighValueCustomers AS (
    SELECT 
        customer.c_customer_sk,
        customer.c_first_name,
        customer.c_last_name,
        RankedSales.total_sales,
        RankedSales.order_count
    FROM 
        customer
    JOIN 
        RankedSales ON customer.c_customer_sk = RankedSales.ws_bill_customer_sk
    WHERE 
        RankedSales.sales_rank <= 100
),

Demographics AS (
    SELECT 
        demographics.cd_demo_sk,
        demographics.cd_gender,
        demographics.cd_marital_status,
        demographics.cd_education_status,
        demographics.cd_dep_count,
        demographics.cd_dep_college_count,
        hv_customers.total_sales,
        hv_customers.order_count
    FROM 
        customer_demographics demographics
    JOIN 
        HighValueCustomers hv_customers ON demographics.cd_demo_sk = hv_customers.c_customer_sk
)

SELECT 
    demographics.cd_gender,
    demographics.cd_marital_status,
    AVG(demographics.total_sales) AS avg_sales,
    COUNT(*) AS customer_count
FROM 
    Demographics demographics
GROUP BY 
    demographics.cd_gender, demographics.cd_marital_status
ORDER BY 
    avg_sales DESC;