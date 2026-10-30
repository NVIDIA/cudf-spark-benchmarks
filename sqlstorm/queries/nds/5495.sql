
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
), CustomerDemographics AS (
    SELECT 
        c.c_customer_sk, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), TopCustomers AS (
    SELECT 
        r.ws_bill_customer_sk, 
        r.total_sales, 
        r.order_count, 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        RankedSales r
    JOIN 
        CustomerDemographics cd ON r.ws_bill_customer_sk = cd.c_customer_sk
    WHERE 
        r.sales_rank <= 10
)
SELECT 
    tc.ws_bill_customer_sk,
    tc.total_sales,
    tc.order_count,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.cd_education_status,
    tc.cd_purchase_estimate,
    CASE 
        WHEN tc.cd_purchase_estimate > 1000 THEN 'High Value'
        WHEN tc.cd_purchase_estimate BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    TopCustomers tc
ORDER BY 
    total_sales DESC;
