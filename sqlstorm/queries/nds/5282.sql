
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_quantity,
        cs.total_sales,
        ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) AS rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_sales > 1000
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        tc.total_quantity,
        tc.total_sales
    FROM 
        customer_demographics cd
    JOIN 
        TopCustomers tc ON cd.cd_demo_sk = tc.c_customer_sk
),
SalesReport AS (
    SELECT 
        cd.cd_gender,
        COUNT(*) AS customer_count,
        AVG(cd.total_sales) AS avg_sales,
        SUM(cd.total_quantity) AS overall_quantity
    FROM 
        CustomerDemographics cd
    GROUP BY 
        cd.cd_gender
)
SELECT 
    sr.cd_gender,
    sr.customer_count,
    sr.avg_sales,
    sr.overall_quantity,
    CASE 
        WHEN sr.avg_sales > 500 THEN 'High Value'
        WHEN sr.avg_sales BETWEEN 200 AND 500 THEN 'Moderate Value'
        ELSE 'Low Value' 
    END AS customer_value_category
FROM 
    SalesReport sr
ORDER BY 
    sr.customer_count DESC;
