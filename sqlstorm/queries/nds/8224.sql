
WITH RankedSales AS (
    SELECT 
        cs_bill_customer_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        COUNT(DISTINCT cs_order_number) AS total_orders,
        RANK() OVER (ORDER BY SUM(cs_ext_sales_price) DESC) AS sales_rank
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) AND 
                              (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        cs_bill_customer_sk
),

CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        CASE 
            WHEN cd_gender = 'M' THEN 'Male'
            WHEN cd_gender = 'F' THEN 'Female'
            ELSE 'Non-Binary'
        END AS gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count
    FROM 
        customer_demographics
),

TopCustomers AS (
    SELECT 
        cs.cs_bill_customer_sk,
        cs.total_sales,
        cs.total_orders,
        cd.gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        RankedSales cs
    JOIN 
        CustomerDemographics cd ON cs.cs_bill_customer_sk = cd.cd_demo_sk
    WHERE 
        cs.sales_rank <= 10
)

SELECT 
    tc.cs_bill_customer_sk,
    tc.total_sales,
    tc.total_orders,
    tc.gender,
    tc.cd_marital_status,
    tc.cd_education_status,
    COALESCE(SUM(ss.ss_quantity), 0) AS total_store_quantity,
    COALESCE(SUM(ws.ws_quantity), 0) AS total_web_quantity
FROM 
    TopCustomers tc
LEFT JOIN 
    store_sales ss ON tc.cs_bill_customer_sk = ss.ss_customer_sk
LEFT JOIN 
    web_sales ws ON tc.cs_bill_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    tc.cs_bill_customer_sk, tc.total_sales, tc.total_orders, tc.gender, tc.cd_marital_status, tc.cd_education_status
ORDER BY 
    total_sales DESC;
