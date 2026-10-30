
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        DENSE_RANK() OVER (ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (
            SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01'
        ) AND (
            SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31'
        )
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate
    FROM 
        customer_demographics
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.c_email_address,
        rs.total_sales,
        rs.order_count,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer cs
    JOIN 
        RankedSales rs ON cs.c_customer_sk = rs.ws_bill_customer_sk
    LEFT JOIN 
        CustomerDemographics cd ON cs.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        rs.sales_rank <= 100
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.c_email_address,
    tc.total_sales,
    tc.order_count,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.cd_education_status
FROM 
    TopCustomers tc
ORDER BY 
    tc.total_sales DESC;
