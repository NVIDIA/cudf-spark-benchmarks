
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1 AND 365
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_demo_sk
    FROM 
        customer_demographics
    WHERE 
        cd_demo_sk IN (SELECT DISTINCT c_current_cdemo_sk FROM customer WHERE c_current_cdemo_sk IS NOT NULL)
),
SalesWithDemographics AS (
    SELECT 
        rs.ws_bill_customer_sk,
        rs.total_sales,
        rs.order_count,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        RankedSales rs
    JOIN 
        CustomerDemographics cd ON rs.ws_bill_customer_sk = cd.cd_demo_sk
    WHERE 
        rs.sales_rank <= 10
)
SELECT 
    swd.ws_bill_customer_sk,
    swd.total_sales,
    swd.order_count,
    swd.cd_gender,
    swd.cd_marital_status,
    swd.cd_education_status,
    swd.cd_purchase_estimate,
    swd.cd_credit_rating
FROM 
    SalesWithDemographics swd
ORDER BY 
    swd.total_sales DESC;
