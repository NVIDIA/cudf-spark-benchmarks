
WITH SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_month_seq IN (5, 6))
        AND (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_month_seq IN (7, 8))
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status
    FROM 
        customer_demographics
),
CustomerInfo AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        c_preferred_cust_flag,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        ss.total_sales,
        ss.order_count
    FROM 
        customer c
    JOIN 
        SalesSummary ss ON c.c_customer_sk = ss.ws_bill_customer_sk
    LEFT JOIN 
        CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.c_preferred_cust_flag,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ci.total_sales,
    ci.order_count
FROM 
    CustomerInfo ci
WHERE 
    ci.total_sales > (SELECT AVG(total_sales) FROM SalesSummary)
ORDER BY 
    total_sales DESC;
