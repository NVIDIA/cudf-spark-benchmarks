
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2451532 AND 2451562  
    GROUP BY 
        ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        ra.ws_bill_customer_sk,
        ra.total_sales,
        ra.order_count,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        RankedSales ra
    JOIN 
        customer_demographics cd ON ra.ws_bill_customer_sk = cd.cd_demo_sk
    WHERE 
        ra.sales_rank <= 10
),
SalesByDemographics AS (
    SELECT 
        cd.cd_education_status AS education_status,
        cd.cd_marital_status AS marital_status,
        COUNT(tc.ws_bill_customer_sk) AS customer_count,
        SUM(tc.total_sales) AS total_sales
    FROM 
        TopCustomers tc
    JOIN 
        customer_demographics cd ON tc.ws_bill_customer_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_education_status, cd.cd_marital_status
)
SELECT 
    education_status, 
    marital_status, 
    customer_count, 
    total_sales
FROM 
    SalesByDemographics
ORDER BY 
    total_sales DESC;
