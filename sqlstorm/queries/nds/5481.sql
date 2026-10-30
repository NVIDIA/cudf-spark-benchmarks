
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2459536 AND 2459860  
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        total_sales,
        order_count
    FROM 
        CustomerSales
    WHERE 
        total_sales > (
            SELECT AVG(total_sales) FROM CustomerSales
        )
),
CustomerDemographics AS (
    SELECT 
        hvc.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        HighValueCustomers hvc
    JOIN 
        customer_demographics cd ON hvc.c_customer_sk = cd.cd_demo_sk
),
SalesByGender AS (
    SELECT 
        cd.cd_gender,
        SUM(hvc.total_sales) AS total_sales_by_gender,
        COUNT(hvc.c_customer_sk) AS customer_count
    FROM 
        HighValueCustomers hvc
    JOIN 
        CustomerDemographics cd ON hvc.c_customer_sk = cd.c_customer_sk
    GROUP BY 
        cd.cd_gender
)
SELECT 
    cd.cd_gender,
    total_sales_by_gender,
    customer_count,
    ROUND(total_sales_by_gender / NULLIF(customer_count, 0), 2) AS avg_sales_per_customer
FROM 
    SalesByGender cd
ORDER BY 
    total_sales_by_gender DESC;
