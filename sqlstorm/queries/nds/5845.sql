
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer_demographics cd
),
SalesWithDemographics AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_orders,
        cs.total_sales,
        cs.total_discount,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    LEFT JOIN 
        Demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
),
RankedCustomers AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY cd_gender ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesWithDemographics
),
TopCustomers AS (
    SELECT 
        *
    FROM 
        RankedCustomers
    WHERE 
        sales_rank <= 10
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_orders,
    tc.total_sales,
    tc.total_discount,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.cd_education_status
FROM 
    TopCustomers tc
ORDER BY 
    tc.cd_gender, tc.total_sales DESC;
