
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    JOIN 
        customer ON ws_bill_customer_sk = c_customer_sk
    WHERE 
        c_first_shipto_date_sk IS NOT NULL
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDemo AS (
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
        r.ws_bill_customer_sk,
        r.total_sales,
        r.total_orders,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        RankedSales r
    JOIN 
        CustomerDemo cd ON r.ws_bill_customer_sk = cd.cd_demo_sk
    WHERE 
        r.sales_rank <= 10
)
SELECT 
    tc.ws_bill_customer_sk,
    tc.total_sales,
    tc.total_orders,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.cd_education_status
FROM 
    TopCustomers tc
ORDER BY 
    tc.total_sales DESC;
