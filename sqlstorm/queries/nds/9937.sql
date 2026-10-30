
WITH SalesSummary AS (
    SELECT 
        ws_bill_customer_sk AS customer_id,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
                             AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        cd.cd_education_status AS education_status,
        cd.cd_dep_count AS dep_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopCustomers AS (
    SELECT 
        ss.customer_id,
        ss.total_quantity,
        ss.total_sales,
        cd.gender,
        cd.marital_status,
        cd.education_status,
        cd.dep_count
    FROM 
        SalesSummary ss
    JOIN 
        CustomerDemographics cd ON ss.customer_id = cd.c_customer_sk
    WHERE 
        ss.total_sales > (SELECT AVG(total_sales) FROM SalesSummary)
    ORDER BY 
        ss.total_sales DESC
    LIMIT 10
)
SELECT 
    tc.customer_id,
    tc.total_quantity,
    tc.total_sales,
    tc.gender,
    tc.marital_status,
    tc.education_status,
    tc.dep_count,
    (SELECT COUNT(*) FROM store_sales ss WHERE ss.ss_customer_sk = tc.customer_id) AS store_purchase_count,
    (SELECT COUNT(*) FROM web_returns wr WHERE wr.wr_returning_customer_sk = tc.customer_id) AS return_count
FROM 
    TopCustomers tc;
