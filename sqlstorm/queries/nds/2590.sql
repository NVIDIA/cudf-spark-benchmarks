
WITH SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_list_price) AS avg_list_price
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
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        cd.cd_dep_count, 
        cd.cd_credit_rating
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopCustomers AS (
    SELECT 
        sd.ws_bill_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        sd.total_sales,
        sd.total_orders
    FROM 
        SalesData sd
    JOIN 
        CustomerDemographics cd ON sd.ws_bill_customer_sk = cd.c_customer_sk
    WHERE 
        sd.total_sales > (
            SELECT AVG(total_sales) FROM SalesData
        )
    ORDER BY 
        sd.total_sales DESC
    LIMIT 10
)
SELECT 
    tc.ws_bill_customer_sk,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.cd_education_status,
    tc.total_sales,
    COALESCE(tc.total_orders, 0) AS total_orders,
    RANK() OVER (ORDER BY tc.total_sales DESC) AS sales_rank
FROM 
    TopCustomers tc
LEFT JOIN 
    (SELECT 
        ws_bill_customer_sk, 
        SUM(ws_ext_discount_amt) AS total_discounts
     FROM 
        web_sales
     GROUP BY 
        ws_bill_customer_sk) wd ON tc.ws_bill_customer_sk = wd.ws_bill_customer_sk
WHERE 
    tc.cd_marital_status IS NOT NULL
ORDER BY 
    sales_rank, tc.ws_bill_customer_sk;
