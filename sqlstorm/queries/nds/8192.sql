
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_sk
), 
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_sales,
        cs.total_orders
    FROM 
        CustomerSales cs
    WHERE 
        cs.sales_rank <= 10
), 
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        tc.total_sales
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    JOIN 
        TopCustomers tc ON c.c_customer_sk = tc.c_customer_sk
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    COUNT(*) AS customer_count,
    AVG(tc.total_sales) AS avg_sales
FROM 
    CustomerDemographics cd
JOIN 
    TopCustomers tc ON cd.total_sales = tc.total_sales
GROUP BY 
    cd.cd_gender, 
    cd.cd_marital_status
ORDER BY 
    customer_count DESC;
